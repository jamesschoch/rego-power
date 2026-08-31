from playwright.sync_api import sync_playwright
import os, shutil, time, json

OUT="/home/claude/video/raw"
shutil.rmtree(OUT, ignore_errors=True); os.makedirs(OUT, exist_ok=True)

AUTOPLAY = """
window.__best=function(){
  if(!running||!piece) return null;
  let best=null, m=piece.m;
  for(let rot=0;rot<4;rot++){
    for(let x=0;x<=COLS-m[0].length;x++){
      if(!legalAt(m,x,piece.src)||!fits(m,x,piece.y)) continue;
      const y=dropY(m,x,piece.y); let g=0,w=0;
      for(let r=0;r<m.length;r++) for(let c=0;c<m[0].length;c++){
        if(!m[r][c]) continue;
        const lvl=ROWS-(y+r);
        if(lvl<=demand[x+c]) g++; else w++;
      }
      const v=g*12-w*45;
      if(!best||v>best.v) best={v,x,m};
    }
    m=rotCW(m);
  }
  return best;
};
window.__t=null;
window.__loop=setInterval(function(){
  if(!running||!piece) return;
  if(!__t){ __t=__best(); if(__t) piece.m=__t.m; }
  if(!__t) return;
  if(piece.x<__t.x) move(1);
  else if(piece.x>__t.x) move(-1);
  else { hardDrop(); __t=null; if(batt>=9) setTimeout(()=>useBattery(),200); }
},55);
"""

with sync_playwright() as p:
    b=p.chromium.launch(args=["--hide-scrollbars"])
    ctx=b.new_context(viewport={"width":540,"height":760},
                      record_video_dir=OUT, record_video_size={"width":540,"height":760})
    pg=ctx.new_page()
    t_start=time.time()
    pg.goto("http://localhost:8899/index.html")
    pg.wait_for_timeout(3000)
    t_play=time.time()-t_start
    pg.evaluate("seenTut=true")
    pg.click("#ovBtn"); pg.wait_for_timeout(600)
    pg.evaluate(AUTOPLAY)
    t0=time.time(); t_done=None
    while time.time()-t0 < 120:
        pg.wait_for_timeout(200)
        if not pg.evaluate("running"):
            t_done=time.time()-t_start; break
    pg.evaluate("clearInterval(window.__loop)")
    stats=pg.evaluate("({regoDay,score,clean:cleanPct(),day})")
    pg.wait_for_timeout(5200)
    ctx.close(); b.close()
json.dump({"t_play":t_play,"t_done":t_done,"stats":stats},open("/home/claude/video/marks.json","w"))
print(t_play, t_done, stats)
