'use strict';
const COURSE=JSON.parse(document.getElementById('course-data').textContent);
const MODELS=JSON.parse(document.getElementById('model-data').textContent);
const SOURCES=JSON.parse(document.getElementById('source-data').textContent);
const DIMENSIONS=JSON.parse(document.getElementById('dimension-data').textContent);
const VALIDATION=JSON.parse(document.getElementById('validation-data').textContent);
const PUBLIC_BASE='https://yhq52045-hub.github.io/lab4/';
const asset=path=>document.body.dataset.offline==='true'?new URL(path,PUBLIC_BASE).href:path;
const $=id=>document.getElementById(id);
const esc=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const steps=COURSE.steps, chapters=COURSE.chapters;
const storageKey='lab4-manual-tutorial-v1';
let current=0, completed=new Set(), activePanel='learn', viewerStage=-1, previousQ='', viewName='iso';
try{
  const saved=JSON.parse(localStorage.getItem(storageKey)||'{}');
  const idx=steps.findIndex(s=>s.id===saved.current); if(idx>=0)current=idx;
  completed=new Set((Array.isArray(saved.completed)?saved.completed:[]).filter(id=>steps.some(s=>s.id===id)));
}catch{}
const qNow=()=>steps[current].q;
const chapterNow=()=>chapters.find(c=>c.id===qNow());
function saveProgress(){try{localStorage.setItem(storageKey,JSON.stringify({current:steps[current].id,completed:[...completed]}));}catch{}}
function updateProgress(){
  const count=steps.filter(s=>completed.has(s.id)).length,pct=Math.round(100*count/steps.length);
  $('progressFill').style.width=pct+'%';$('progressNumber').textContent=`${count} / ${steps.length} 步骤完成`;
  document.querySelector('[role=progressbar]').setAttribute('aria-valuenow',pct);
}
function renderNav(){
  const query=$('stepSearch').value.trim().toLowerCase(); let lastPhase='',html='',found=0;
  steps.forEach((s,i)=>{
    if(query?!JSON.stringify(s).toLowerCase().includes(query):s.q!==qNow())return;
    found++;const phase=s.q+' / '+s.phase;
    if(phase!==lastPhase){html+=`<div class="nav-phase">${esc(query?s.q+' · '+s.phase:s.phase)}</div>`;lastPhase=phase;}
    const n=steps.filter((p,j)=>j<=i&&p.q===s.q).length;
    html+=`<button class="step-link ${i===current?'active ':''}${completed.has(s.id)?'done':''}" data-step="${i}" ${i===current?'aria-current="step"':''}><span class="nav-number">${completed.has(s.id)?'✓':String(n).padStart(2,'0')}</span><span>${esc(s.title)}</span></button>`;
  });
  $('stepNav').innerHTML=html||(found?'':'<p class="empty-search">没有匹配步骤，试试“圆”“拉伸”或题号。</p>');
  $('stepNav').querySelectorAll('[data-step]').forEach(b=>b.onclick=()=>selectStep(+b.dataset.step));
}
function renderChapterNav(){
  $('chapterNav').innerHTML=chapters.map(c=>`<button data-chapter="${c.id}" class="${c.id===qNow()?'active':''}" aria-pressed="${c.id===qNow()}">${c.id==='start'?'操作基础':c.id}<small>${steps.filter(s=>s.q===c.id).length} 步</small></button>`).join('');
  $('chapterNav').querySelectorAll('button').forEach(b=>b.onclick=()=>{
    $('stepSearch').value='';selectStep(steps.findIndex(s=>s.q===b.dataset.chapter));
  });
}
function dimensionsTable(rows){return `<table class="dimensions-table"><tbody>${rows.map(([a,b])=>`<tr><td>${esc(a)}</td><td>${esc(b)}</td></tr>`).join('')}</tbody></table>`;}
function stepMarkup(s){
  return `<div class="step-kicker"><span>${esc(s.q==='start'?'GETTING STARTED':s.q)} / ${esc(s.phase)}</span><span>${s.q==='Q5'?'全部尺寸为教学近似值':s.q==='Q4'?'本题单位：in':'单位：mm（基础页除外）'}</span></div><h2>${esc(s.title)}</h2><div class="command-path">${esc(s.command)}</div><ol class="actions">${s.actions.map(a=>`<li>${esc(a)}</li>`).join('')}</ol>${s.dimensions.length?`<div class="parameter-label">本步输入与定位 / VALUES</div>${dimensionsTable(s.dimensions)}`:''}<div class="check-box"><b>✓ 做完后应该看到</b><p>${esc(s.check)}</p></div><div class="fix-box"><b>容易做错的地方</b><p>${esc(s.fix)}</p></div>`;
}
function renderStep(){
  const s=steps[current],c=chapterNow(),q=s.q,qChanged=previousQ!==q;
  $('chapterEnglish').textContent=c.en.toUpperCase();$('chapterTitle').textContent=c.title;$('chapterSubtitle').textContent=c.subtitle;
  $('chapterUnit').textContent=q==='start'?'从这里开始':`${c.unit==='in'?'IPS · 英寸':'MMGS · 毫米'}${q==='Q5'?' · 近似值':''}`;
  $('instruction').innerHTML=stepMarkup(s);
  $('stepComplete').checked=completed.has(s.id);
  const local=steps.filter(p=>p.q===q),at=local.findIndex(p=>p.id===s.id)+1;
  $('stepPosition').textContent=`${at} / ${local.length}`;
  $('prevStep').disabled=current===0;$('nextStep').disabled=current===steps.length-1;
  $('nextStep').textContent=current===steps.length-1?'已到最后一步':(steps[current+1].q!==q?`进入 ${steps[current+1].q} →`:'下一步 →');
  $('sketchDiagram').innerHTML=diagramSVG(s.diagram);
  const notice=q==='Q4'?'单位核对：原文写 mm，但参考体积为 in³；本教程按英寸重建。原点按原图位于上表面，厚度向下 0.3in。':q==='Q5'?'近似建模：全部数值沿用原网站的教学设定；原题没有精确尺寸。实体特征只使用拉伸凸台与拉伸切除。':'';
  $('questionNotice').hidden=!notice;$('questionNotice').textContent=notice;
  $('stageSelect').innerHTML='<option value="-1">空白零件 / 尚未生成实体</option>'+(MODELS[q]||[]).map((m,i)=>`<option value="${i}">${String(i+1).padStart(2,'0')} · ${esc(m.title)}</option>`).join('');
  $('stageSelect').disabled=q==='start';
  viewerStage=s.stage; $('stageSelect').value=String(viewerStage);$('syncStage').hidden=true;
  if(qChanged){setView('iso',false);previousQ=q;}
  updateStageCaption(); renderChapterNav();renderNav();renderDimensions();renderSource();updateProgress();saveProgress();
  if(qChanged)fitView(); else renderModel();
}
function selectStep(index){
  if(!Number.isInteger(index)||index<0||index>=steps.length)return;
  current=index;setPanel('learn');renderStep();
  $('sidebar').classList.remove('open');$('menuToggle').setAttribute('aria-expanded','false');
}
function setPanel(name){
  activePanel=name;
  document.querySelectorAll('.panel').forEach(p=>p.hidden=p.id!=='panel-'+name);
  document.querySelectorAll('.tab').forEach(t=>{const on=t.dataset.panel===name;t.classList.toggle('active',on);t.setAttribute('aria-selected',on);t.tabIndex=on?0:-1;});
  if(name==='learn')requestAnimationFrame(fitView);
}
function updateStageCaption(){
  const seq=MODELS[qNow()]||[],s=seq[viewerStage],manual=viewerStage!==steps[current].stage;
  $('stageNumber').textContent=s?`${String(viewerStage+1).padStart(2,'0')} / ${String(seq.length).padStart(2,'0')}`:'尚无实体';
  $('emptyState').hidden=!!s;
  $('canvasTag').textContent=qNow()==='start'?'NEW PART':qNow()+(qNow()==='Q5'?' · APPROXIMATE':'')+' · GEOMETRY PREVIEW';
  $('modelStageTitle').textContent=s?s.title:'本步尚未创建实体';
  $('modelHint').textContent=manual?'正在手动查看其他实体阶段。点击“返回本步”恢复对应状态。':s?'显示截至本步已完成的实体；正在编辑的草图请看下方尺寸示意。':'先按操作建立草图，再执行拉伸；下方示意帮助定位。';
  $('syncStage').hidden=!manual;
  const unit=qNow()==='Q4'?'in³':'mm³',vol=s?s.volume/(qNow()==='Q4'?25.4**3:1):null;
  $('stageVolume').textContent=vol===null?'—':`${vol.toLocaleString('en-US',{minimumFractionDigits:3,maximumFractionDigits:qNow()==='Q4'?6:3})} ${unit}`;
}
function renderDimensions(){
  const selected=qNow()==='start'?chapters.filter(c=>c.id!=='start'):[chapterNow()];
  $('dimensionContent').innerHTML=selected.map(c=>{
    const rows=DIMENSIONS[c.id]||[],v=VALIDATION.checks.find(x=>x.question===c.id);
    return `<article class="card dimension-summary"><h3>${esc(c.title)}</h3><p class="small muted">${c.id==='Q5'?'下列所有数值均为教学近似设定。':`本题长度单位：${c.unit}`}</p><table class="summary-table"><thead><tr><th scope="col">参数 / 位置</th><th scope="col">尺寸 / 数值</th><th scope="col">来源</th></tr></thead><tbody>${rows.map(([a,b,kind])=>`<tr><td>${esc(a)}</td><td>${esc(b)}</td><td><span class="source-kind ${kind==='教学设定'?'chosen':''}">${esc(kind)}</span></td></tr>`).join('')}</tbody></table><p class="small muted">${c.reference===null?'没有原题参考体积。':`参考体积 ${c.reference} ${c.unit}³ ±1%；CAD 几何核验偏差 ${v.percent_error>=0?'+':''}${v.percent_error.toFixed(4)}%。`}</p></article>`;
  }).join('');
}
function renderSource(){
  const q=qNow()==='start'?'Q1':qNow(),c=SOURCES[q];
  $('sourceTitle').textContent=q==='Q5'?'原网站保留的 Lab3 第4题配图':`${q} · 本次 Lab4 PDF 原始尺寸图`;
  $('sourceImage').src=c.sourceURL;$('sourceImage').alt=q+' 原始配图（点击放大）';
  $('sourceText').innerHTML=`<h3>${q} · 原题要求与中文释义</h3>`+c.original.map(([en,zh])=>`<p class="source-en">${esc(en)}</p><p class="source-zh">${esc(zh)}</p>`).join('')+(q==='Q5'?'<p class="important-note">Lab4 本次附件仅引用 Lab3；此处 Lab3 配图取自原网站，示例尺寸也沿用原网站，并非本次附件给定。</p>':q==='Q4'?'<p class="important-note">保留原文的 mm / in³ 矛盾。本教程采用 in 输入，并按侧视原点将实体放在上表面以下。</p>':'');
}
function openSource(){
  const q=qNow()==='start'?'Q1':qNow();$('dialogTitle').textContent=q+' · 原始配图';$('dialogImage').src=SOURCES[q].sourceURL;
  if(typeof $('sourceDialog').showModal==='function')$('sourceDialog').showModal();else $('sourceDialog').setAttribute('open','');
}
function closeSource(){if(typeof $('sourceDialog').close==='function')$('sourceDialog').close();else $('sourceDialog').removeAttribute('open');}

// Small self-contained CAD viewer. Geometry is in teaching (u,v,h), in mm.
const cv=$('cv'),glcv=$('glcv'),ctx=cv.getContext('2d');
let gl=null,program,buffer,posloc,colloc;
try{
  gl=glcv.getContext('webgl',{alpha:true,preserveDrawingBuffer:true,antialias:true});
  if(gl){
    const shader=(type,src)=>{const s=gl.createShader(type);gl.shaderSource(s,src);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error('shader');return s;};
    program=gl.createProgram();gl.attachShader(program,shader(gl.VERTEX_SHADER,'attribute vec3 pos;attribute vec3 col;varying vec3 color;void main(){gl_Position=vec4(pos,1.0);color=col;}'));
    gl.attachShader(program,shader(gl.FRAGMENT_SHADER,'precision mediump float;varying vec3 color;void main(){gl_FragColor=vec4(color,1.0);}'));
    gl.linkProgram(program);if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw Error('link');gl.useProgram(program);
    buffer=gl.createBuffer();posloc=gl.getAttribLocation(program,'pos');colloc=gl.getAttribLocation(program,'col');
  }
}catch{gl=null;}
if(!gl)glcv.hidden=true;
let az=-1.05,el=.48,scale=4,center=[0,0,0],width=500,height=330,drag=null;
const stageModel=()=>MODELS[qNow()]?.[viewerStage];
function modelBounds(){const m=MODELS[qNow()]?.at(-1);if(!m)return [[-25,25],[-25,25],[0,50]];return [0,1,2].map(i=>{let min=Infinity,max=-Infinity;for(const p of m.vertices){min=Math.min(min,p[i]);max=Math.max(max,p[i]);}return [min,max];});}
function project(p){
  const x=p[0]-center[0],y=p[1]-center[1],z=p[2]-center[2],a=Math.cos(az),b=Math.sin(az),ce=Math.cos(el),se=Math.sin(el),xx=-b*x+a*y,depth=a*x+b*y;
  return [width/2+scale*xx,height/2-scale*(ce*z-se*depth),ce*depth+se*z];
}
function fitView(){
  const b=modelBounds();center=b.map(([a,z])=>(a+z)/2);scale=1;width=cv.clientWidth||500;height=cv.clientHeight||330;
  const m=MODELS[qNow()]?.at(-1);if(m){let minX=Infinity,maxX=-Infinity,minY=Infinity,maxY=-Infinity;for(const p of m.vertices){const a=project(p);minX=Math.min(minX,a[0]);maxX=Math.max(maxX,a[0]);minY=Math.min(minY,a[1]);maxY=Math.max(maxY,a[1]);}scale=.76*Math.min(width/(maxX-minX||1),height/(maxY-minY||1));}
  renderModel();
}
function setView(name,draw=true){
  viewName=name;
  if(name==='front'){az=-Math.PI/2;el=0;}else if(name==='top'){az=-Math.PI/2;el=Math.PI/2;}else if(name==='right'){az=0;el=0;}else{az=qNow()==='Q3'?-2.3:qNow()==='Q1'?1.05:-1.05;el=.48;}
  document.querySelectorAll('[data-view]').forEach(b=>b.setAttribute('aria-pressed',b.dataset.view===name));if(draw)fitView();
}
function drawGL(m,points,dpr){
  glcv.width=Math.round(width*dpr);glcv.height=Math.round(height*dpr);gl.viewport(0,0,glcv.width,glcv.height);gl.clearColor(0,0,0,0);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);
  const range=Math.max(...modelBounds().map(([a,b])=>b-a))*2,arr=[];
  for(const f of m.faces){
    const a=m.vertices[f[0]],b=m.vertices[f[1]],c=m.vertices[f[2]],u=b.map((x,i)=>x-a[i]),v=c.map((x,i)=>x-a[i]),n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]],len=Math.hypot(...n)||1;
    const light=.59+.37*Math.abs((n[0]*.3-n[1]*.4+n[2]*.8)/len);
    for(const i of f){const p=points[i];arr.push(2*p[0]/width-1,1-2*p[1]/height,-p[2]/range,.40*light,.66*light,.55*light);}
  }
  gl.bindBuffer(gl.ARRAY_BUFFER,buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(arr),gl.DYNAMIC_DRAW);gl.enableVertexAttribArray(posloc);gl.vertexAttribPointer(posloc,3,gl.FLOAT,false,24,0);gl.enableVertexAttribArray(colloc);gl.vertexAttribPointer(colloc,3,gl.FLOAT,false,24,12);gl.enable(gl.DEPTH_TEST);gl.depthFunc(gl.LEQUAL);gl.drawArrays(gl.TRIANGLES,0,arr.length/6);
  if($('showEdges').checked){const earr=[];for(const e of m.edges){const p=e.points.map(project);for(let j=1;j<p.length;j++)for(const a of [p[j-1],p[j]])earr.push(2*a[0]/width-1,1-2*a[1]/height,-a[2]/range-.00002,.17,.34,.28);}
    gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(earr),gl.DYNAMIC_DRAW);gl.drawArrays(gl.LINES,0,earr.length/6);
  }
}
function drawSoftware(m,ps){
  const faces=m.faces.map(f=>({f,depth:f.reduce((n,i)=>n+ps[i][2],0)/3})).sort((a,b)=>a.depth-b.depth);
  for(const {f} of faces){const a=m.vertices[f[0]],b=m.vertices[f[1]],c=m.vertices[f[2]],u=b.map((x,i)=>x-a[i]),v=c.map((x,i)=>x-a[i]),n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]],l=.6+.32*Math.abs((n[0]*.3-n[1]*.4+n[2]*.8)/(Math.hypot(...n)||1));ctx.fillStyle=`rgb(${Math.round(102*l)},${Math.round(168*l)},${Math.round(140*l)})`;ctx.beginPath();f.forEach((i,j)=>{j?ctx.lineTo(ps[i][0],ps[i][1]):ctx.moveTo(ps[i][0],ps[i][1]);});ctx.closePath();ctx.fill();}
  if($('showEdges').checked){ctx.strokeStyle='#375c4e80';ctx.lineWidth=.7;for(const e of m.edges){ctx.beginPath();e.points.forEach((p,i)=>{const a=project(p);i?ctx.lineTo(a[0],a[1]):ctx.moveTo(a[0],a[1]);});ctx.stroke();}}
}
function renderModel(){
  if(activePanel!=='learn'||!ctx)return;
  const dpr=Math.min(window.devicePixelRatio||1,2);width=cv.clientWidth||500;height=cv.clientHeight||330;
  cv.width=Math.round(width*dpr);cv.height=Math.round(height*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,width,height);
  const m=stageModel();if(!m){if(gl){gl.viewport(0,0,glcv.width,glcv.height);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);}return;}
  const ps=m.vertices.map(project);if(gl)drawGL(m,ps,dpr);else drawSoftware(m,ps);
  const length=Math.max(...modelBounds().map(([a,b])=>b-a))*.15;
  for(const [i,col,label] of [[0,'#b55c50','u'],[1,'#448268','v'],[2,'#4f77a4','h']]){const end=[0,0,0];end[i]=length;const a=project([0,0,0]),b=project(end);ctx.strokeStyle=col;ctx.lineWidth=1.6;ctx.beginPath();ctx.moveTo(a[0],a[1]);ctx.lineTo(b[0],b[1]);ctx.stroke();ctx.fillStyle=col;ctx.font='11px system-ui';ctx.fillText(label,b[0]+4,b[1]-4);}
  const o=project([0,0,0]);ctx.fillStyle='#d87998';ctx.beginPath();ctx.arc(o[0],o[1],3.5,0,Math.PI*2);ctx.fill();
}
cv.addEventListener('pointerdown',e=>{drag={x:e.clientX,y:e.clientY};if(cv.setPointerCapture)cv.setPointerCapture(e.pointerId);});
cv.addEventListener('pointermove',e=>{if(!drag)return;az-=(e.clientX-drag.x)*.009;el=Math.max(-1.56,Math.min(1.56,el+(e.clientY-drag.y)*.009));drag={x:e.clientX,y:e.clientY};document.querySelectorAll('[data-view]').forEach(b=>b.setAttribute('aria-pressed','false'));renderModel();});
for(const event of ['pointerup','pointercancel','lostpointercapture'])cv.addEventListener(event,()=>drag=null);
cv.addEventListener('wheel',e=>{e.preventDefault();scale=Math.max(.02,Math.min(10000,scale*Math.exp(-e.deltaY*.001)));renderModel();},{passive:false});
glcv.addEventListener('webglcontextlost',e=>{e.preventDefault();gl=null;glcv.hidden=true;renderModel();});
document.querySelectorAll('[data-view]').forEach(b=>b.onclick=()=>setView(b.dataset.view));$('fitView').onclick=fitView;$('showEdges').onchange=renderModel;
$('stageSelect').onchange=()=>{viewerStage=Number($('stageSelect').value);updateStageCaption();renderModel();};
$('syncStage').onclick=()=>{viewerStage=steps[current].stage;$('stageSelect').value=String(viewerStage);updateStageCaption();renderModel();};

$('totalSteps').textContent=steps.length;$('totalStages').textContent=Object.values(MODELS).reduce((n,a)=>n+a.length,0);
$('modelLinks').innerHTML=['Q1','Q2','Q3','Q4','Q5'].map(q=>`<a href="${asset('./files/'+q+'.step')}" download>${q} STEP${q==='Q4'?' · 原点已修正':''}</a>`).join('');
$('provenanceList').innerHTML=COURSE.provenance.map(t=>`<li>${esc(t)}</li>`).join('');
$('officialLinks').innerHTML=COURSE.references.map(([label,url])=>`<a href="${esc(url)}" target="_blank" rel="noopener">${esc(label)} ↗</a>`).join('');
$('stepSearch').oninput=renderNav;
$('prevStep').onclick=()=>selectStep(current-1);$('nextStep').onclick=()=>selectStep(current+1);
$('stepComplete').onchange=()=>{if($('stepComplete').checked)completed.add(steps[current].id);else completed.delete(steps[current].id);saveProgress();updateProgress();renderNav();};
$('resetProgress').onclick=()=>{if(window.confirm('重置当前浏览器保存的全部 Lab4 学习进度？')){completed.clear();current=0;$('stepSearch').value='';selectStep(0);}};
$('menuToggle').onclick=()=>{const open=$('sidebar').classList.toggle('open');$('menuToggle').setAttribute('aria-expanded',open);};
document.querySelectorAll('.tab').forEach(t=>t.onclick=()=>setPanel(t.dataset.panel));
document.querySelector('.tabs').onkeydown=e=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(e.key))return;e.preventDefault();const tabs=[...document.querySelectorAll('.tab')],at=tabs.indexOf(document.activeElement);const index=e.key==='Home'?0:e.key==='End'?tabs.length-1:(at+(e.key==='ArrowRight'?1:-1)+tabs.length)%tabs.length;tabs[index].focus();setPanel(tabs[index].dataset.panel);};
for(const id of ['openSource','sourceZoom','sourceImageButton'])$(id).onclick=openSource;
$('closeDialog').onclick=closeSource;$('sourceDialog').onclick=e=>{if(e.target===$('sourceDialog'))closeSource();};
document.addEventListener('keydown',e=>{if(e.key==='Escape'){$('sidebar').classList.remove('open');$('menuToggle').setAttribute('aria-expanded','false');}});
$('downloadOffline').onclick=()=>{
  const copy=document.documentElement.cloneNode(true);
  copy.querySelector('body').dataset.offline='true';
  copy.querySelectorAll('a[href]').forEach(a=>{const href=a.getAttribute('href');if(href&&!href.startsWith('#')&&!/^(data:|blob:|mailto:|https?:)/i.test(href))a.setAttribute('href',new URL(href,PUBLIC_BASE).href);});
  copy.querySelector('#sourceDialog').removeAttribute('open');
  const blob=new Blob(['<!doctype html>\n'+copy.outerHTML],{type:'text/html;charset=utf-8'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='Lab4_Step_by_Step.html';a.click();setTimeout(()=>URL.revokeObjectURL(url),30000);
};
function buildPrint(){
  $('printContent').innerHTML=`<h1 class="print-title">Lab 4 · SOLIDWORKS 逐步操作教程</h1><p class="print-notice">Q1—Q3 用 mm；Q4 按 in 解释，并保留原 PDF 单位矛盾；Q5 全部尺寸为教学近似设定。教学坐标 (u,v,h) 对应 SOLIDWORKS (X,Y,Z)=(u,h,−v)。教程为手动操作指导，未在本环境运行 SOLIDWORKS。</p>`+chapters.map(c=>`<section class="print-chapter"><h2>${esc(c.title)}</h2>${steps.filter(s=>s.q===c.id).map((s,i)=>`<article class="print-step"><h3>${i+1}. ${esc(s.title)}</h3><p class="command-path">${esc(s.command)}</p><ol>${s.actions.map(a=>`<li>${esc(a)}</li>`).join('')}</ol>${s.dimensions.length?dimensionsTable(s.dimensions):''}<p><b>检查：</b>${esc(s.check)}</p><p><b>易错点：</b>${esc(s.fix)}</p></article>`).join('')}</section>`).join('');
}
$('printCourse').onclick=()=>{buildPrint();window.print();};window.addEventListener('beforeprint',buildPrint);
window.addEventListener('resize',()=>{if(activePanel==='learn')fitView();});
if(typeof ResizeObserver!=='undefined')new ResizeObserver(()=>{if(activePanel==='learn')fitView();}).observe(cv.parentElement);
renderStep();setPanel('learn');
