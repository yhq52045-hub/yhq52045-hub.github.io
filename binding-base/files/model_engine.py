#!/usr/bin/env python3
"""Rebuild Binding Base Plate teaching stages (mm) from workbook pp.74–95.

Open CASCADE BREP / STEP reference geometry, not a native SOLIDWORKS model.
See validation.json for supplemental assumptions and explicit limitations.
Edit PARAMS or a parameters.json copy and rerun:
python model_engine.py --params parameters.json --out model_assets
"""
from __future__ import annotations
import os
from pathlib import Path
os.environ.setdefault('XDG_CACHE_HOME', str(Path(__file__).parent/'cache'))
import math,json,argparse,time
import cadquery as cq

PARAMS = dict(length=225.,bottom_width=80.,top_width=40.,plan_radius=75.,
    block_height=25.,thickness=3.,left_run=40.,right_run=65.,tab_width=25.,
    tab_offset=4.,tab_height=32.,tab_thickness=3.,tab1_start=120.,tab2_start=70.,
    slot_outer_radius=14.,slot_end_radius=1.5,slot_chord=6.,slot_center_gap=6.,
    slot_top_inset=6.,inside_bend_radius=3.,outer_fillet=15.,tab_top_fillet=6.,
    root_fillet=2.,hole_diameter=76.,hole_from_right=50.,hole_from_flat_bottom=110.,
    K=0.5)
CENTER=(-50.,110.,0.)
NOTES=[]

def V(p): return cq.Vector(*p)
def edge(a,b):return cq.Edge.makeLine(V(a),V(b))
def arc(a,m,b):return cq.Edge.makeThreePointArc(V(a),V(m),V(b))
def wire(edges):return cq.Wire.assembleEdges(edges)
def face(edges):return cq.Face.makeFromWires(wire(edges))
def prism(f,v):return cq.Solid.extrudeLinear(f.outerWire(),f.innerWires(),V(v))
def rect_face(points):return cq.Face.makeFromWires(cq.Wire.makePolygon([V(x) for x in points+[points[0]]]))
def fuse(*shapes):
    a=shapes[0]
    for b in shapes[1:]: a=a.fuse(b)
    return a.clean()
def box(x,y,z,dx,dy,dz):return cq.Solid.makeBox(dx,dy,dz,V((x,y,z)))

def derived(p):
    R=p['plan_radius'];C=(-p['top_width'],p['length']-R);P=(-p['bottom_width'],0.)
    vx,vy=P[0]-C[0],P[1]-C[1];d2=vx*vx+vy*vy
    ts=[(C[0]+R*R*vx/d2+s*R*math.sqrt(d2-R*R)*(-vy)/d2,C[1]+R*R*vy/d2+s*R*math.sqrt(d2-R*R)*vx/d2) for s in [-1,1]]
    T=min(ts,key=lambda x:x[0]); L=math.dist(P,T);t=((T[0]-P[0])/L,(T[1]-P[1])/L)
    n=(-t[1],t[0]);h=p['block_height']/2
    r0=(p['left_run']**2+h*h)/(2*h);r1=(p['right_run']**2+h*h)/(2*h)
    ang0=math.atan2(p['left_run'],r0-h);ang1=math.atan2(p['right_run'],r1-h)
    # K is measured from the inner surface. Outer radius minus (1-K)*thickness.
    rn0=r0-(1-p['K'])*p['thickness'];rn1=r1-(1-p['K'])*p['thickness']
    fmin=p['left_run']-rn0*ang0;fmax=p['length']-p['right_run']+rn1*ang1
    return dict(C=C,T=T,P=P,side_t=t,side_n=n,side_length=L,r0=r0,r1=r1,a0=ang0,a1=ang1,
                rn0=rn0,rn1=rn1,flat_min=fmin,flat_max=fmax,hole_y=fmin+p['hole_from_flat_bottom'])

D=derived(PARAMS)

def plan_face(p=PARAMS,rounded=False):
    d=derived(p);P=d['P'];T=d['T'];C=d['C'];U=(-p['top_width'],p['length']);Q=(0.,p['length'])
    aa=math.atan2(T[1]-C[1],T[0]-C[0]);bb=math.pi/2
    if aa<bb:aa+=2*math.pi
    # clockwise from the low-left tangent to the upper point
    mm=(aa+bb)/2
    M=(C[0]+p['plan_radius']*math.cos(mm),C[1]+p['plan_radius']*math.sin(mm),0)
    F=face([edge((0,0,0),(*P,0)),edge((*P,0),(*T,0)),arc((*T,0),M,(*U,0)),edge((*U,0),(*Q,0)),edge((*Q,0),(0,0,0))])
    if rounded:
        targets=[(0,0),P,Q]
        verts=[v for v in F.Vertices() if any(math.hypot(v.X-a,v.Y-b)<1e-5 for a,b in targets)]
        F=F.fillet2D(p['outer_fillet'],verts)
    return F

def stage01_block(p=PARAMS):return prism(plan_face(p),(0,0,p['block_height']))

def side_band_face(p=PARAMS):
    d=derived(p);r0,r1=d['r0'],d['r1'];t=p['thickness'];run=p['left_run'];end=p['length']-p['right_run'];x=-200.
    def zz(y,z):return(x,y,z)
    def pt(cy,cz,R,ang):return zz(cy+R*math.sin(ang),cz-R*math.cos(ang))
    A=pt(run,r0,r0,-d['a0']);B=zz(run,0);C=zz(end,0);E=pt(end,r1,r1,d['a1'])
    Ei=pt(end,r1,r1-t,d['a1']);Ci=zz(end,t);Bi=zz(run,t);Ai=pt(run,r0,r0-t,-d['a0'])
    return face([arc(A,pt(run,r0,r0,-d['a0']/2),B),edge(B,C),arc(C,pt(end,r1,r1,d['a1']/2),E),edge(E,Ei),arc(Ei,pt(end,r1,r1-t,d['a1']/2),Ci),edge(Ci,Bi),arc(Bi,pt(run,r0,r0-t,-d['a0']/2),Ai),edge(Ai,A)])

def stage02_cookie_plate(p=PARAMS,rounded=False):
    band=prism(side_band_face(p),(250,0,0))
    block=prism(plan_face(p,rounded),(0,0,p['block_height']))
    return block.intersect(band).clean()

SIDES=[dict(name='Straight',base=(0.,0.),t=(0.,1.),n=(1.,0.)),
       dict(name='Tapered',base=D['P'],t=D['side_t'],n=D['side_n'])]

def gp(side,s,q,z):
    return (side['base'][0]+side['t'][0]*s+side['n'][0]*q,
            side['base'][1]+side['t'][1]*s+side['n'][1]*q,z)
def local_rect(side,s0,s1,q,z0,z1):
    return rect_face([gp(side,s0,q,z0),gp(side,s1,q,z0),gp(side,s1,q,z1),gp(side,s0,q,z1)])
def tab_rect(side,start,p=PARAMS,round_top=False,bottom=0.):
    F=local_rect(side,start,start+p['tab_width'],p['tab_offset'],bottom,p['tab_height'])
    if round_top:
        F=F.fillet2D(p['tab_top_fillet'],[v for v in F.Vertices() if abs(v.Z-p['tab_height'])<1e-6])
    return prism(F,(side['n'][0]*p['tab_thickness'],side['n'][1]*p['tab_thickness'],0))
def tab_offset(side,start,p=PARAMS):
    return prism(local_rect(side,start,start+p['tab_width'],0,0,p['thickness']),
                 (side['n'][0]*p['tab_offset'],side['n'][1]*p['tab_offset'],0))

def slot_face(side,start,mirror,p=PARAMS,q=-3.):
    R=p['slot_outer_radius'];cap=p['slot_end_radius'];rn=R-cap;ri=R-2*cap
    a=math.asin((p['slot_center_gap']/2)/rn);b=a+2*math.asin(p['slot_chord']/(2*rn))
    zc=p['tab_height']-p['slot_top_inset']-math.sqrt(rn*rn-(p['slot_center_gap']/2)**2)
    mid=start+p['tab_width']/2
    def pp(r,ang):return gp(side,mid+mirror*r*math.sin(ang),q,zc+r*math.cos(ang))
    def cp(ang,sgn):
        return gp(side,mid+mirror*(rn*math.sin(ang)+sgn*cap*math.cos(ang)),q,zc+rn*math.cos(ang)-sgn*cap*math.sin(ang))
    return face([arc(pp(R,a),pp(R,(a+b)/2),pp(R,b)),arc(pp(R,b),cp(b,1),pp(ri,b)),
                 arc(pp(ri,b),pp(ri,(a+b)/2),pp(ri,a)),arc(pp(ri,a),cp(a,-1),pp(R,a))])
def slot_cutter(side,start,p=PARAMS):
    return fuse(*[prism(slot_face(side,start,m,p),(side['n'][0]*15,side['n'][1]*15,0)) for m in [-1,1]])
def square_tab(side,start,p=PARAMS,slots=False):
    S=fuse(tab_offset(side,start,p),tab_rect(side,start,p))
    return S.cut(slot_cutter(side,start,p)).clean() if slots else S

def bent_tab(side,start,p=PARAMS,round_top=False):
    # Inner R3 / outer R6 with the original vertical faces q4 and q7.
    th=p['thickness'];ri=p['inside_bend_radius'];ro=ri+th
    qc=p['tab_offset']-ri;zc=ro
    def pp(q,z):return gp(side,start,q,z)
    f=face([arc(pp(qc,0),pp(qc+ro/math.sqrt(2),zc-ro/math.sqrt(2)),pp(qc+ro,zc)),
            edge(pp(qc+ro,zc),pp(qc+ri,zc)),
            arc(pp(qc+ri,zc),pp(qc+ri/math.sqrt(2),zc-ri/math.sqrt(2)),pp(qc,th)),edge(pp(qc,th),pp(qc,0))])
    bend=prism(f,(side['t'][0]*p['tab_width'],side['t'][1]*p['tab_width'],0))
    foot=prism(local_rect(side,start,start+p['tab_width'],0,0,th),(side['n'][0]*qc,side['n'][1]*qc,0))
    upper=tab_rect(side,start,p,round_top,bottom=zc)
    return fuse(foot,bend,upper).cut(slot_cutter(side,start,p)).clean()

def root_patch_face(side,s,qmax,direction,p=PARAMS):
    R=p['root_fillet']
    # Filled concave rounding outside a tab side. Local coordinate u points away from the tab.
    def pp(u,q):return gp(side,s+direction*u,q,0)
    # patch is square R*R minus quarter circle centered (R,R)
    return face([edge(pp(0,0),pp(R,0)),arc(pp(R,0),pp(R-R/math.sqrt(2),R-R/math.sqrt(2)),pp(0,R)),edge(pp(0,R),pp(0,0))])

def bent_root_patch(side,s,direction,p=PARAMS):
    R=p['root_fillet'];th=p['thickness'];ri=p['inside_bend_radius'];ro=ri+th;rn=ri+p['K']*th;qc=p['tab_offset']-ri
    # Plane portion of the R2 relief blend, then a smooth loft over its short bent part.
    F=root_patch_face(side,s,R,direction,p)
    pad=prism(F,(0,0,th))
    if qc>=R:return pad
    plane=pad.intersect(prism(rect_face([gp(side,s-5,0,-1),gp(side,s+5,0,-1),gp(side,s+5,qc,-1),gp(side,s-5,qc,-1)]),(0,0,th+2))).clean()
    wires=[]
    for i in range(21):
        f=i/20; q=qc+(R-qc-0.02)*f
        width=R-math.sqrt(max(0,R*R-(q-R)**2))
        # u = 0 .. width, with the in-plane R2 circular edge.
        theta=(q-qc)/rn
        qo=qc+ro*math.sin(theta);zo=ro-ro*math.cos(theta)
        qi=qc+ri*math.sin(theta);zi=ro-ri*math.cos(theta)
        pts=[gp(side,s,qo,zo),gp(side,s+direction*width,qo,zo),gp(side,s+direction*width,qi,zi),gp(side,s,qi,zi)]
        wires.append(cq.Wire.makePolygon([V(a) for a in pts+[pts[0]]]))
    loft=cq.Solid.makeLoft(wires,True)
    return fuse(plane,loft)


def flatten_y(y,p=PARAMS):
    d=derived(p);lo=p['left_run'];hi=p['length']-p['right_run']
    if y<lo:
        ang=math.asin(max(-1,min(1,(lo-y)/d['r0'])))
        return lo-d['rn0']*ang
    if y>hi:
        ang=math.asin(max(-1,min(1,(y-hi)/d['r1'])))
        return hi+d['rn1']*ang
    return y

def flat_base_face(p=PARAMS,rounded=False):
    # The original plan outline is unrolled at the neutral layer; curved side edges
    # are represented by a dense planar spline (not a forged native flat pattern).
    d=derived(p);C=d['C'];T=d['T'];P=d['P'];R=p['plan_radius']
    pts=[(0.,flatten_y(0,p),0.),(P[0],flatten_y(0,p),0.)]
    for i in range(1,71):
        f=i/70; x=P[0]+f*(T[0]-P[0]);y=P[1]+f*(T[1]-P[1]);pts.append((x,flatten_y(y,p),0.))
    at=math.atan2(T[1]-C[1],T[0]-C[0]);ae=math.pi/2
    if at<ae:at+=2*math.pi
    for i in range(1,111):
        a=at+(ae-at)*i/110;x=C[0]+R*math.cos(a);y=C[1]+R*math.sin(a);pts.append((x,flatten_y(y,p),0.))
    pts += [(0.,flatten_y(p['length'],p),0.)]
    # Separate line/spline edges to avoid hundreds of tiny polygon edges.
    e=[edge(pts[0],pts[1]),cq.Edge.makeSpline([V(a) for a in pts[1:72]]),cq.Edge.makeSpline([V(a) for a in pts[71:182]]),edge(pts[181],pts[182]),edge(pts[182],pts[0])]
    F=face(e)
    if rounded:
        targets=[pts[0],pts[1],pts[-1]]
        vs=[v for v in F.Vertices() if any((V(v.toTuple())-V(t)).Length<1e-5 for t in targets)]
        try:F=F.fillet2D(p['outer_fillet'],vs)
        except Exception as ex:
            NOTES.append('Exact planar R15 fillet of the unrolled spline contour failed: '+str(ex))
            # Use the R15-rounded original plan mask, consistently unrolled using samples.
            F=flat_rounded_sampled(p)
    return F

def flat_rounded_sampled(p=PARAMS):
    F=plan_face(p,True);edges=[]
    for e in F.outerWire().Edges():
        samples=e.discretize(45 if e.geomType()!='LINE' else 30)
        ps=[V((a.x,flatten_y(a.y,p),0.)) for a in samples]
        edges.append(cq.Edge.makeSpline(ps) if len(ps)>2 else cq.Edge.makeLine(*ps))
    return face(edges)

def flat_tab_face(side,start,p=PARAMS,round_top=False):
    ri=p['inside_bend_radius'];th=p['thickness'];rn=ri+p['K']*th;qc=p['tab_offset']-ri;zc=ri+th
    length=qc+rn*math.pi/2+(p['tab_height']-zc)
    f=rect_face([gp(side,start,0,0),gp(side,start+p['tab_width'],0,0),gp(side,start+p['tab_width'],length,0),gp(side,start,length,0)])
    if round_top:
        vs=[]
        for v in f.Vertices():
            q=(v.X-side['base'][0])*side['n'][0]+(v.Y-side['base'][1])*side['n'][1]
            if abs(q-length)<1e-5:vs.append(v)
        f=f.fillet2D(p['tab_top_fillet'],vs)
    return f

def flat_slot_cutter(side,start,p=PARAMS):
    ri=p['inside_bend_radius'];th=p['thickness'];rn=ri+p['K']*th;qc=p['tab_offset']-ri;zc=ri+th
    # Above the tab bend, h maps linearly to neutral length q_flat.
    offset=qc+rn*math.pi/2-zc
    R=p['slot_outer_radius'];cap=p['slot_end_radius'];rm=R-cap;rinner=R-2*cap
    a=math.asin(p['slot_center_gap']/2/rm);b=a+2*math.asin(p['slot_chord']/2/rm)
    cenZ=p['tab_height']-p['slot_top_inset']-math.sqrt(rm*rm-(p['slot_center_gap']/2)**2)
    mid=start+p['tab_width']/2;cutters=[]
    for mirror in [-1,1]:
        def pp(r,ang):return gp(side,mid+mirror*r*math.sin(ang),offset+cenZ+r*math.cos(ang),-1)
        def cp(ang,sgn):return gp(side,mid+mirror*(rm*math.sin(ang)+sgn*cap*math.cos(ang)),offset+cenZ+rm*math.cos(ang)-sgn*cap*math.sin(ang),-1)
        F=face([arc(pp(R,a),pp(R,(a+b)/2),pp(R,b)),arc(pp(R,b),cp(b,1),pp(rinner,b)),arc(pp(rinner,b),pp(rinner,(a+b)/2),pp(rinner,a)),arc(pp(rinner,a),cp(a,-1),pp(R,a))])
        cutters.append(prism(F,(0,0,p['thickness']+2)))
    return fuse(*cutters)

def flat_shape(p=PARAMS,rounded=False,hole=False):
    S=prism(flat_base_face(p,rounded),(0,0,p['thickness']))
    for side,start in [(SIDES[0],p['tab1_start']),(SIDES[1],p['tab2_start'])]:
        S=fuse(S,prism(flat_tab_face(side,start,p,rounded),(0,0,p['thickness'])))
        S=S.cut(flat_slot_cutter(side,start,p)).clean()
        if rounded:
            for s,direction in [(start,-1),(start+p['tab_width'],1)]:
                S=fuse(S,prism(root_patch_face(side,s,p['root_fillet'],direction,p),(0,0,p['thickness'])))
    if hole:S=S.cut(cq.Solid.makeCylinder(p['hole_diameter']/2,p['thickness']+2,V((-p['hole_from_right'],derived(p)['hole_y'],-1)))).clean()
    return S

def final_bent(p=PARAMS,rounded=False,hole=False):
    S=stage02_cookie_plate(p,rounded)
    for side,start in [(SIDES[0],p['tab1_start']),(SIDES[1],p['tab2_start'])]:
        S=fuse(S,bent_tab(side,start,p,rounded))
        if rounded:
            for s,direction in [(start,-1),(start+p['tab_width'],1)]:S=fuse(S,bent_root_patch(side,s,direction,p))
    if hole:S=S.cut(cq.Solid.makeCylinder(p['hole_diameter']/2,8,V((-p['hole_from_right'],derived(p)['hole_y'],-2)))).clean()
    return S

def metrics(name,s):
    from OCP.Bnd import Bnd_Box
    from OCP.BRepBndLib import BRepBndLib
    b=Bnd_Box();BRepBndLib.AddOptimal_s(s.wrapped,b,False,False);mnx,mny,mnz,mxx,mxy,mxz=b.Get()
    return dict(name=name,valid=s.isValid(),solids=len(s.Solids()),volume_mm3=s.Volume(),area_mm2=s.Area(),bbox_mm=[mxx-mnx,mxy-mny,mxz-mnz],bounds_mm=[mnx,mny,mnz,mxx,mxy,mxz],faces=len(s.Faces()))
def mesh(name,s):
    vs,tris=s.tessellate(0.22,0.12);vertices=[];normals=[]
    for ids in tris:
        a,b,c=[vs[i] for i in ids];cross=(b-a).cross(c-a)
        if cross.Length<1e-12:continue
        n=cross.normalized()
        for v in [a,b,c]:
            vertices.extend([round(v.x-CENTER[0],5),round(v.y-CENTER[1],5),round(v.z-CENTER[2],5)])
            normals.extend([round(n.x,5),round(n.y,5),round(n.z,5)])
    return dict(name=name,vertices=vertices,normals=normals)

def build(out,p=PARAMS):
    global SIDES
    d=derived(p)
    SIDES=[dict(name='Straight',base=(0.,0.),t=(0.,1.),n=(1.,0.)),
           dict(name='Tapered',base=d['P'],t=d['side_t'],n=d['side_n'])]
    NOTES.clear()
    out=Path(out);out.mkdir(parents=True,exist_ok=True);stages=[];meshes=[];logs=[]
    def add(n,f):
        t=time.time();print('BUILD',n,flush=True);s=f();m=metrics(n,s);stages.append((n,s));logs.append(m)
        print(json.dumps(m),f'[{time.time()-t:.2f}s]',flush=True)
        if not m['valid'] or m['solids']!=1:NOTES.append(f'{n}: valid={m["valid"]}, solids={m["solids"]}')
        meshes.append(mesh(n,s));return s
    block=add('01_Block_25mm',lambda:stage01_block(p))
    base=add('02_Cookie_Cut_3mm',lambda:stage02_cookie_plate(p))
    off=add('03_First_Offset_4mm',lambda:fuse(base,tab_offset(SIDES[0],p['tab1_start'],p)))
    ear1=add('04_First_Tab_32x3',lambda:fuse(off,tab_rect(SIDES[0],p['tab1_start'],p)))
    sl1=add('05_First_Twin_Arc_Slots',lambda:ear1.cut(slot_cutter(SIDES[0],p['tab1_start'],p)).clean())
    both=add('06_Second_Tab_and_Slots',lambda:fuse(sl1,square_tab(SIDES[1],p['tab2_start'],p,True)))
    bent=add('07_Insert_Bends_R3',lambda:final_bent(p))
    flat=add('08_Flattened_Before_Fillets',lambda:flat_shape(p))
    fr=add('09_Flattened_R15_R6_R2',lambda:flat_shape(p,True))
    br=add('10_Refolded_Rounded',lambda:final_bent(p,True))
    fh=add('11_Flattened_Hole_D76',lambda:flat_shape(p,True,True))
    final=add('12_Final_Refolded_Plate',lambda:final_bent(p,True,True))
    cq.exporters.export(final,str(out/'Binding_Base_Plate_FINAL.step'))
    cq.exporters.export(fh,str(out/'Binding_Base_Plate_FLAT_K0p5.step'))
    # BREP cache supports re-opening exact stage geometry for independent validation.
    for name,s in stages:s.exportBrep(str(out/(name+'.brep')))
    (out/'meshes.json').write_text(json.dumps(meshes,separators=(',',':')))
    roundtrip=[]
    for filename, original in [('Binding_Base_Plate_FINAL.step',final),('Binding_Base_Plate_FLAT_K0p5.step',fh)]:
        imported=cq.importers.importStep(str(out/filename)).val()
        check=metrics(filename,imported);check['volume_difference_mm3']=imported.Volume()-original.Volume();roundtrip.append(check)
    validation=dict(units='mm',source_pages=[74,95],parameters=p,derived=derived(p),mesh_origin=list(CENTER),
        stages=logs,step_roundtrip=roundtrip,flat_bent_volume_difference_mm3=final.Volume()-fh.Volume(),software='CadQuery 2.7 / Open CASCADE; not SOLIDWORKS',native_sldprt_generated=False,
        assumptions=['K=0.5 is a configurable supplemental assumption; the workbook does not state a K factor.',
                     'The hole is dimensioned in the developed flat state; its folded fixed-face Y is derived from the lower neutral arc.',
                     'Only supplied Tasks 1–8 are modeled; no opposite-foot mirror or assembly is asserted.'],
        limitations=['STEP is exact BREP for the delivered reference solid but contains no native SOLIDWORKS sketch/feature history.',
                     'Flat base side contours use a sampled spline neutral-layer unrolling. Native SOLIDWORKS Insert Bends / Ignore beveled faces may trim the bevels differently.',
                     'Final outer corner R15 cuts are applied to the original plan mask before intersection with the curved sheet. They are visually and dimensionally R15 in plan, not a verified R15 circle on a native unfolded blank.',
                     'R6 tab upper corners and R14/R11/R1.5 arc slots are exact planar CAD arcs. R2 root blends are reconstructed using a 21-section ruled loft over the short bend portion; they are not a native SOLIDWORKS unfolded fillet.',
                     'Flat/bent stages are reference constructions, not a claim of an exact volume-preserving native sheet-metal unfold/refold.'],
        build_notes=NOTES)
    (out/'validation.json').write_text(json.dumps(validation,ensure_ascii=False,indent=2))
    (out/'parameters.json').write_text(json.dumps(p,ensure_ascii=False,indent=2))
    print('DONE',out,flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--out',default=str(Path(__file__).parent/'model_assets'))
    parser.add_argument('--params',type=Path,help='Optional JSON object of millimeter parameters and K factor')
    args=parser.parse_args()
    params=dict(PARAMS)
    if args.params:
        supplied=json.loads(args.params.read_text())
        unknown=set(supplied)-set(params)
        if unknown:parser.error('Unknown parameter names: '+', '.join(sorted(unknown)))
        for key,value in supplied.items():
            if isinstance(value,bool) or not isinstance(value,(int,float)) or not math.isfinite(value):
                parser.error('Parameters must be finite numbers: '+key)
        params.update(supplied)
    if not 0<=params['K']<=1:parser.error('K must be between 0 and 1')
    if any(value<=0 for key,value in params.items() if key!='K'):
        parser.error('Millimeter dimensions must be positive')
    if abs(params['thickness']-params['tab_thickness'])>1e-8:
        parser.error('Sheet thickness and tab_thickness must match for this uniform-thickness reference')
    build(args.out,params)
