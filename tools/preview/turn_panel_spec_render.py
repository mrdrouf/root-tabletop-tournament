from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
import math
LUM="/System/Library/Fonts/Supplemental/Luminari.ttf"
SRC=Image.open("crafted.png").convert("RGB")
S=2; W_UI=440; H_FULL=366
FIELD=(249,230,187); INK=(0,0,0); WELL=(255,255,255)
PLAQUE=(226,196,138); INKPL=(26,18,10); CREAM=(249,230,187)
def F(pt): return ImageFont.truetype(LUM, int(round(pt*S)))
def px(v): return int(round(v*S))

def ink_layer(rgb):
    """RGB crop of Root art -> RGBA where the ink is opaque and the cream is clear."""
    g=rgb.convert("L")
    a=g.point(lambda v: 255 if v<70 else (0 if v>190 else int(255*(190-v)/120)))
    out=Image.new("RGBA", rgb.size, (0,0,0,0))
    out.putalpha(a)
    ink=Image.new("RGBA", rgb.size, (17,13,10,255)); ink.putalpha(a)
    return ink

def border_layers(W,H):
    """REAL crafted-improvements rim, unrepeated, scaled 1.19x."""
    K = W/740.0                       # 880/740 = 1.189
    t = SRC.crop((0,0,740,36)).resize((W,int(36*K)), Image.LANCZOS)
    b = SRC.crop((0,1919,740,1955)).resize((W,int(36*K)), Image.LANCZOS)
    hs = int(H/K)
    l = SRC.crop((0,200,36,200+hs)).resize((int(36*K),H), Image.LANCZOS)
    r = SRC.crop((704,200,740,200+hs)).resize((int(36*K),H), Image.LANCZOS)
    return [(ink_layer(t),(0,0)),(ink_layer(b),(0,H-b.size[1])),
            (ink_layer(l),(0,0)),(ink_layer(r),(W-r.size[0],0))]

# --- the real slot frame, 9-sliced -------------------------------------------
SLOT=(85,279,655,1071)      # outer box of the big card slot, stroke 18, radius 27
def slot_frame(w,h,scale=0.55):
    """9-slice Root's own card-slot outline to w x h (px). Returns an ink RGBA."""
    x0,y0,x1,y1=SLOT
    C=int(70)                                  # corner square in SOURCE px
    src=SRC.crop(SLOT)
    sw,sh=src.size
    c=int(round(C*scale)); 
    out=Image.new("RGB",(w,h),(255,255,255))
    def put(box_src, box_dst):
        piece=src.crop(box_src).resize((box_dst[2]-box_dst[0], box_dst[3]-box_dst[1]), Image.LANCZOS)
        out.paste(piece,(box_dst[0],box_dst[1]))
    put((0,0,C,C),(0,0,c,c));                 put((sw-C,0,sw,C),(w-c,0,w,c))
    put((0,sh-C,C,sh),(0,h-c,c,h));           put((sw-C,sh-C,sw,sh),(w-c,h-c,w,h))
    put((C,0,sw-C,C),(c,0,w-c,c));            put((C,sh-C,sw-C,sh),(c,h-c,w-c,h))
    put((0,C,C,sh-C),(0,c,c,h-c));            put((sw-C,C,sw,sh-C),(w-c,c,w,h-c))
    lay=ink_layer(out)
    # interior fully transparent: the plate colour underneath shows through
    m=Image.new("L",(w,h),255)
    from PIL import ImageDraw as _D
    _D.Draw(m).rectangle([c,c,w-c-1,h-c-1], fill=0)
    lay.putalpha(Image.composite(lay.getchannel("A"), Image.new("L",(w,h),0), m))
    return lay

def paper(im):
    w,h=im.size
    n=Image.effect_noise((w,h),16).filter(ImageFilter.GaussianBlur(1.1*S))
    return Image.blend(im, Image.merge("RGB",[n]*3), 0.045)

def spaced(d,cx,top,text,pt,fill,track):
    f=F(pt); adv=[f.getlength(ch) for ch in text]
    tot=sum(adv)+track*S*(len(text)-1); x=cx*S-tot/2
    for ch,a in zip(text,adv): d.text((x,top*S),ch,font=f,fill=fill); x+=a+track*S

RW=(30,60,160,168); TW=(180,60,410,168)
TITLE_TOP=24; TITLE_PT=25; TITLE_TRACK=5
M=30; BAR_H=60; Y_DEAL=200; Y_START=274

def build(with_deal=True, rnd="4", clock="3:07"):
    H=H_FULL if with_deal else H_FULL-74
    Wp,Hp=W_UI*S,H*S
    im=Image.new("RGB",(Wp,Hp),FIELD); im=paper(im)
    im=im.convert("RGBA")
    # wells and bars
    def plate(box, fill, sc):
        x0,y0,x1,y1=[v*S for v in box]
        w,h=x1-x0,y1-y0
        d=ImageDraw.Draw(im); d.rounded_rectangle([x0,y0,x1,y1],radius=px(14),fill=fill)
        im.alpha_composite(slot_frame(w,h,sc),(x0,y0))
    plate(RW, WELL, 0.50); plate(TW, WELL, 0.50)
    ys=[Y_DEAL,Y_START] if with_deal else [Y_DEAL]
    labs=["DEAL 5 CARDS","START TURN 1"] if with_deal else ["START TURN 1"]
    fills=[PLAQUE,INKPL] if with_deal else [INKPL]
    tcs=[INKPL,CREAM] if with_deal else [CREAM]
    for y,lab,fl,tc in zip(ys,labs,fills,tcs):
        plate((M,y,W_UI-M,y+BAR_H), fl, 0.40)
    for l,(pos,fill) in zip(border_layers(Wp,Hp),[(0,0)]*4):
        pass
    for lay,pos in border_layers(Wp,Hp): im.alpha_composite(lay,pos)
    d=ImageDraw.Draw(im)
    for box,lab in [(RW,"ROUND"),(TW,"TIME")]:
        bb=F(TITLE_PT).getbbox("H")
        spaced(d,(box[0]+box[2])/2, TITLE_TOP-bb[1]/S, lab, TITLE_PT, INK, TITLE_TRACK)
    for y,lab,tc in zip(ys,labs,tcs):
        f=F(45); bb=f.getbbox(lab)
        d.text((W_UI/2*S-f.getlength(lab)/2,(y+BAR_H/2)*S-(bb[3]+bb[1])/2),lab,font=f,fill=tc)
    cy=(RW[1]+RW[3])/2
    f=F(100); bb=f.getbbox(rnd)
    d.text(((RW[0]+RW[2])/2*S-f.getlength(rnd)/2, cy*S-(bb[3]+bb[1])/2), rnd, font=f, fill=INK)
    pt=92 if len(clock)<=4 else 78
    f=F(pt); cd=0.60*pt*S; cc=0.28*pt*S
    cells=[(ch, cc if ch==':' else cd) for ch in clock]
    tot=sum(w for _,w in cells); x=(TW[0]+TW[2])/2*S-tot/2; bb=f.getbbox("0")
    for ch,wd in cells:
        d.text((x+(wd-f.getlength(ch))/2, cy*S-(bb[3]+bb[1])/2), ch, font=f, fill=INK); x+=wd
    return im.convert("RGB")
build(True).save("p3_full.png"); build(False,"7","12:41").save("p3_short.png")
print("ok")
