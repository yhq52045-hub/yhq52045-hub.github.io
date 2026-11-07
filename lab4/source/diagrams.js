'use strict';
function diagramSVG(key) {
  const ink='#244d47', teal='#137f78', pale='#e1eee5', orange='#bf6c38', grey='#b5c6bb';
  const line=(x1,y1,x2,y2,c=ink,dash='')=>`<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${c}" ${dash?'stroke-dasharray="'+dash+'"':''}/>`;
  const text=(x,y,t,c=ink,size=13,anchor='middle')=>`<text x="${x}" y="${y}" fill="${c}" font-size="${size}" text-anchor="${anchor}">${t}</text>`;
  const rect=(x,y,w,h,fill=pale,stroke=ink)=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${fill}" stroke="${stroke}" stroke-width="1.5"/>`;
  const circle=(x,y,r,fill='none',stroke=ink,dash='')=>`<circle cx="${x}" cy="${y}" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width="1.5" ${dash?'stroke-dasharray="'+dash+'"':''}/>`;
  const dot=(x,y,label='O')=>circle(x,y,4,'#df7997','#fff')+text(x-10,y+19,label,'#b45377',11);
  const dimH=(x1,x2,y,t,from)=>line(x1,y-7,x1,y+7,grey)+line(x2,y-7,x2,y+7,grey)+line(x1,y,x2,y,grey)+text((x1+x2)/2,y-8,t,teal,12)+(from===undefined?'':line(x1,from,x1,y,grey,'3 3')+line(x2,from,x2,y,grey,'3 3'));
  const dimV=(x,y1,y2,t)=>line(x-6,y1,x+6,y1,grey)+line(x-6,y2,x+6,y2,grey)+line(x,y1,x,y2,grey)+text(x+13,(y1+y2)/2+4,t,teal,12,'start');
  let body='',title='草图定位与尺寸';
  if(!key){
    title='先认清三个基准面';
    body=`<path d="M125 230L300 145L470 230L300 310Z" fill="#dceee6" stroke="${grey}"/><path d="M125 230V80L300 20V145Z" fill="#eef2e8" stroke="${grey}"/><path d="M300 145V20L470 80V230Z" fill="#e0e9e9" stroke="${grey}"/>`;
    body+=line(300,145,465,225,teal)+line(300,145,140,223,teal)+line(300,145,300,35,teal)+dot(300,145)+text(485,238,'u',teal,16)+text(120,237,'v',teal,16)+text(300,15,'h',teal,16)+text(300,325,'Front：v=0 · Top：h=0 · Right：u=0',ink,12);
  } else if(key.startsWith('q1-') && key!=='q1-hole') {
    const specs={'q1-base':[60,28,0,30],'q1-s1':[48,20,30,8],'q1-s2':[32,20,38,12],'q1-tall':[20,20,50,25]};
    const [a,b,h,d]=specs[key],s=5.3,x=95,y=75;
    title='俯视草图 · mm'; body=rect(x,y,60*s,28*s,'#f2f4ef',grey)+rect(x,y,a*s,b*s,pale,teal)+dot(x,y)+dimH(x,x+a*s,267,String(a),y)+dimV(450,y,y+b*s,String(b));
    body+=text(290,35,`草图面 h=${h} · 本次向上拉伸 ${d}`,ink,13)+text(290,308,'所有台阶从同一个 (u,v)=(0,0) 角定位',ink,12);
  } else if(key==='q1-hole') {
    title='底座立面 · mm'; const x=95,y=82,s=5.3,bottom=y+30*s,cx=x+44*s,cy=bottom-16*s;
    body=rect(x,y,60*s,30*s)+circle(cx,cy,6*s,'#fff')+line(cx-45,cy,cx+45,cy,grey,'5 3')+line(cx,cy-45,cx,cy+45,grey,'5 3')+dot(x,bottom)+dimH(cx,x+60*s,55,'16',y)+dimV(453,cy,bottom,'16')+dimH(x,cx,285,'44 = 60−16',bottom)+text(265,328,'孔 Ø12 · 沿深度贯穿 28',ink,13);
  } else if(key.startsWith('q2-')) {
    if(key==='q2-large'||key==='q2-small') {
      title='侧面高度关系 · mm';
      body=rect(105,105,330,30)+rect(105,65,145,40)+rect(350,135,85,120)+line(85,135,465,135,grey,'5 4')+dimV(70,65,135,'14')+dimV(470,105,135,'6')+dimV(470,135,255,'24')+text(290,303,'Top Plane：h=0；板顶 h=6；小端底 h=−24',ink,12)+text(155,47,'在板顶追加 8',teal,12)+dot(178,135);
    } else {
      title='俯视相切轮廓 · mm';const R=80,r=45,cx=175,sx=365,y=165,nx=7/38,ny=Math.sqrt(1-nx*nx),bx=cx+nx*R,by=ny*R,tx=sx+nx*r,ty=ny*r;
      body=`<path d="M${bx} ${y-by} L${tx} ${y-ty} A${r} ${r} 0 0 1 ${tx} ${y+ty} L${bx} ${y+by} A${R} ${R} 0 1 1 ${bx} ${y-by}Z" fill="${pale}" stroke="${ink}" stroke-width="1.5"/>`;
      body+=circle(cx,y,R,'none',grey,'4 4')+circle(sx,y,r,'none',grey,'4 4')+line(75,y,430,y,grey,'6 4')+dot(cx,y)+circle(sx,y,3,teal,teal)+dimH(cx,sx,280,'圆心距 38',y)+text(158,54,'大端外径 Ø32',ink,12)+text(395,83,'小端 R9',ink,12);
      if(key==='q2-holes')body+=circle(cx,y,50,'#fff')+circle(sx,y,15,'#fff')+text(cx,y+6,'Ø20',teal,12)+text(sx,y-23,'Ø6',teal,12);
      else body+=text(290,322,'两条公外切线都必须与两圆相切',ink,12);
    }
  } else if(['q3-base','q3-wall','q3-opening'].includes(key)) {
    title='俯视定位 · mm'; const x=160,y=35,s=4.8;
    body=`<path d="M${x+10*s} ${y} H${x+35*s} V${y+52*s} H${x+10*s} A${10*s} ${10*s} 0 0 1 ${x} ${y+42*s} V${y+10*s} A${10*s} ${10*s} 0 0 1 ${x+10*s} ${y}Z" fill="${pale}" stroke="${ink}" stroke-width="1.5"/>`;
    body+=dot(x,y+26*s)+line(x-15,y+26*s,x+35*s+15,y+26*s,grey,'5 4')+dimH(x,x+35*s,316,'前后 35')+dimV(110,y,y+52*s,'宽 52');
    if(key!=='q3-base')body+=rect(x+9*s,y+9*s,26*s,34*s,'#bddbc9',teal)+text(440,80,'外宽 34',teal,12)+text(440,105,'前后 26',teal,12)+text(440,130,'前端 u=9',teal,12);
    else body+=text(440,90,'前端两角',ink,12)+text(440,114,'R10',teal,15)+text(440,160,'底板厚 7',ink,12);
    if(key==='q3-opening')body+=rect(x+16*s,y+16*s,20*s,20*s,'#fff3e6',orange)+text(440,205,'开口宽 20',orange,12)+text(440,230,'实际深 19',orange,12)+text(440,255,'底板也切穿',orange,12);
  } else if(key==='q3-root') {
    title='横向剖面示意 · R5 根部过渡';
    body=`<path d="M95 275V240H165 Q190 240 190 215 V70H410V215 Q410 240 435 240H505V275Z" fill="${pale}" stroke="${ink}" stroke-width="1.5"/>`+`<path d="M165 240Q190 240 190 215 M410 215Q410 240 435 240" fill="none" stroke="${orange}" stroke-width="4"/>`+text(300,41,'立台高 25（自底板顶面起）',ink,13)+text(300,310,'只选两侧根部凹棱；不是顶面外棱',ink,12)+text(132,203,'R5',orange,15)+text(470,203,'R5',orange,15);
  } else if(key==='q3-lug') {
    title='耳板正对草图面 · mm';const cx=285,cy=145,r=67.5,base=217;
    body=`<path d="M${cx-r} ${base} V${cy} A${r} ${r} 0 0 1 ${cx+r} ${cy} V${base}Z" fill="${pale}" stroke="${ink}" stroke-width="1.5"/>`+circle(cx,cy,27,'#fff')+line(cx,55,cx,260,grey,'6 4')+line(185,cy,390,cy,grey,'6 4')+dimH(cx-r,cx+r,263,'宽 15')+dimV(175,cy,base,'8')+text(435,87,'顶弧 R7.5',ink,13)+text(435,121,'孔 Ø6',teal,13)+text(435,166,'厚 5，向 +u',ink,12)+text(290,306,'底边 h=7 · 孔心 h=15 · 最高 h=22.5',ink,12);
  } else if(key==='q4-left'||key==='q4-jaw') {
    title='左端详图 · 所有数值为 in';const cx=290,cy=170,R=95,xcut=cx-.25/.4*R,dy=Math.sqrt(R*R-(cx-xcut)**2),tip=cx+.15/.4*R;
    body=`<path d="M${xcut} ${cy-dy} A${R} ${R} 0 1 1 ${xcut} ${cy+dy}Z" fill="${pale}" stroke="${ink}" stroke-width="1.5"/>`;
    if(key==='q4-jaw')body+=`<path d="M180 ${cy-59.375}H${cx}L${tip} ${cy}L${cx} ${cy+59.375}H180Z" fill="#fff" stroke="${orange}" stroke-width="1.8"/>`;
    body+=line(cx,62,cx,280,grey,'5 4')+line(185,cy,410,cy,grey,'5 4')+dot(tip,cy)+circle(cx,cy,2.5,teal,teal)+dimH(xcut,cx,45,'0.25')+dimH(xcut,tip,306,'0.4')+text(460,105,'外圆 Ø0.8',ink,13)+text(460,143,'圆心 u=−0.15',ink,12)+text(460,180,'截平线 u=−0.4',ink,12);
    if(key==='q4-jaw')body+=text(460,220,'开口宽 0.5',orange,13)+text(460,246,'尖点 = 原点',orange,12);
  } else if(key==='q4-outline'||key==='q4-hex') {
    title='平面外形 · in';const s=104,x0=100,y=153,a=Math.sqrt(.4*.4-.2*.2),right=-.15+2*a+3.25,px=u=>x0+u*s,py=v=>y-v*s,clipy=Math.sqrt(.4*.4-.25*.25);
    body=`<path d="M${px(-.4)} ${py(clipy)} A${.4*s} ${.4*s} 0 0 1 ${px(-.15+a)} ${py(.2)} H${px(right-a)} A${.4*s} ${.4*s} 0 1 1 ${px(right-a)} ${py(-.2)} H${px(-.15+a)} A${.4*s} ${.4*s} 0 0 1 ${px(-.4)} ${py(-clipy)}Z" fill="${pale}" stroke="${ink}" stroke-width="1.5"/>`;
    body+=dimH(px(-.15+a),px(right-a),240,'外露直边 3.25')+dimV(285,py(.2),py(-.2),'0.4')+dot(px(0),y)+text(300,49,'厚 0.3，Top Plane 上表面向下拉伸',ink,12)+text(300,297,'右圆心 u=3.7928203230；左圆心 u=−0.15',ink,12);
    if(key==='q4-hex'){
      const r=.5/Math.sqrt(3),p=Array.from({length:6},(_,i)=>[px(right+r*Math.cos(i*Math.PI/3)),py(r*Math.sin(i*Math.PI/3))]);
      body+=`<polygon points="${p.map(p=>p.join(',')).join(' ')}" fill="#fff" stroke="${teal}"/>`+text(475,82,'六角对边距 0.5',teal,12);
    }
  } else if(['q5-body','q5-rise','q5-hole'].includes(key)) {
    title='Front 草图方向 · 全部为教学近似值';const px=u=>105+u*5.6,py=h=>286-h*5.0;
    const points=[[0,20],[12,0],[60,0],[60,40],[12,40]];
    body=`<polygon points="${points.map(([u,h])=>px(u)+','+py(h)).join(' ')}" fill="${pale}" stroke="${ink}" stroke-width="1.5"/>`;
    if(key==='q5-rise')body+=`<polygon points="${[[0,20],[8,47],[8,20]].map(([u,h])=>px(u)+','+py(h)).join(' ')}" fill="#fff0e0" stroke="${orange}" stroke-width="1.8"/>`+text(210,32,'峰点 (8,47)',orange,12);
    if(key==='q5-hole')body+=`<ellipse cx="${px(40)}" cy="${py(20)}" rx="${10*5.6}" ry="${10*5}" fill="#fff" stroke="${teal}"/>`+text(px(40),py(20)+5,'Ø20',teal,12)+text(296,42,'圆心 u=40，h=20；各侧向内盲切 4',ink,12);
    body+=dot(px(0),py(0))+dimH(px(0),px(60),317,'总长 60')+dimV(475,py(40),py(0),'40')+text(100,py(20)-12,'(0,20)',ink,11)+text(207,py(0)-12,'u=12',ink,11);
  } else if(key==='q5-opening') {
    title='Top 草图方向 · 教学近似尺寸'; const s=5,x=105,y=45;
    body=rect(x,y,60*s,48*s)+rect(x+8*s,y+6*s,48*s,36*s,'#fff',orange)+line(x,y+24*s,x+60*s,y+24*s,grey,'5 4')+dimH(x+8*s,x+56*s,312,'开口长 48')+dimV(450,y+6*s,y+42*s,'36')+text(290,28,'开口 u=8…56，v=±18；高度贯穿',ink,12)+text(510,93,'侧壁 6',teal,12)+text(510,121,'端壁 4',teal,12)+dot(x,y+24*s);
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 345" role="img" aria-label="${title}" style="font-family:system-ui,Microsoft YaHei,sans-serif;stroke-linejoin:round;stroke-linecap:round"><title>${title}</title>${body}</svg>`;
}
