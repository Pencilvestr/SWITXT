"""Run pinned native targets in isolated processes; verify logs and framebuffer pixels."""
from pathlib import Path
import argparse, concurrent.futures, hashlib, json, subprocess, sys
from PIL import Image, ImageChops
from worker import SIZES

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
RESULTS=ROOT/'work/native-results'

def run_one(radio):
    dest=RESULTS/radio
    dest.mkdir(parents=True,exist_ok=True)
    log=dest/'firmware.log'
    with log.open('w') as output:
        try:
            proc=subprocess.run([sys.executable,str(HERE/'worker.py'),'--radio',radio],stdout=output,stderr=subprocess.STDOUT,timeout=45)
            code=proc.returncode
        except subprocess.TimeoutExpired: code=-1
    text=log.read_text(errors='replace')
    rows={int(p[1]):p for line in text.splitlines() if line.startswith('CHECK|') for p in [line.split('|')]}
    w,h=SIZES[radio];color=h>64
    labels={1:'ARMED',2:'DISARMED',3:'MOTOR OFF',4:'ARMED',5:''}
    if color: labels.update({6:'ARMED',8:'ARMED',9:'ARMED',10:'',11:'DISARMED'})
    checks={'process_exit':code==0,
            'no_script_error':not any(s in text for s in ['PANIC','Script syntax error','Script error','attempt to call','attempt to index','not enough memory','CPU limit','Error in widget','Traceback']),
            'phase_labels':all(i in rows and rows[i][2]==label for i,label in labels.items()),
            'native_version':all(p[5]=='2.12.5' for p in rows.values()) and bool(rows),
            'switch_evaluation':all(i in rows and rows[i][6]==state for i,state in {1:'true,false,false',2:'false,true,false',3:'false,false,true',4:'true,true,true',5:'false,false,false'}.items()),
            'production_copy_unchanged':(dest/('sd/WIDGETS/SWITXT/main.lua' if color else 'sd/SCRIPTS/TELEMETRY/switxt.lua')).read_bytes()==(ROOT/('main.lua' if color else 'mono/switxt.lua')).read_bytes()}
    images={}
    expected=['armed','disarmed','motor-off','priority','blank']
    if color: expected+=['small','long-small','normal','fullscreen','fullscreen-blank','returned']
    for name in expected:
        path=dest/(name+'.png')
        if path.exists():
            im=Image.open(path).convert('RGB');images[name]=im
            checks['frame_'+name]=im.size==(w,h)
        else: checks['frame_'+name]=False
    if 'blank' in images:
        blank=images['blank']
        # The widget layout has its decorations disabled; inactive screens must be uniform.
        checks['blank_clears_pixels']=len(blank.getcolors(w*h) or [])==1
        checks['visible_labels']=all(name in images and ImageChops.difference(images[name],blank).getbbox() is not None for name in ['armed','disarmed','motor-off'])
        boxes=[ImageChops.difference(images[name],blank).getbbox() for name in ['armed','disarmed','motor-off'] if name in images]
        checks['labels_clear_of_edges']=len(boxes)==3 and all(b and b[0]>=2 and b[1]>=2 and b[2]<=w-2 and b[3]<=h-2 for b in boxes)
        checks['priority_matches_first']=('priority' in images and ImageChops.difference(images['priority'],images['armed']).getbbox() is None)
    if color:
        checks['fits_native_font_metrics']=all(p[3]=='true' for p in rows.values())
        checks['long_label_has_ellipsis']=7 in rows and rows[7][2].endswith('...')
        checks['real_fullscreen_and_return']=all(i in rows and rows[i][4]==value for i,value in {8:'false',9:'true',10:'true',11:'false'}.items())
        checks['fullscreen_clears_pixels']='fullscreen-blank' in images and len(images['fullscreen-blank'].getcolors(w*h) or [])==1
        checks['saved_option_values']='NATIVE_DEFAULTS|ARMED|DISARMED|MOTOR OFF' in text
        checks['configured_colors_render']=all(
            name in images and any(predicate(*pixel) for _,pixel in (images[name].getcolors(w*h) or []))
            for name,predicate in [('armed',lambda r,g,b:g>r+50 and g>b+50),
                                   ('disarmed',lambda r,g,b:r>g+50 and r>b+50),
                                   ('motor-off',lambda r,g,b:r>g+20 and g>b+30)])
    result={'radio':radio,'resolution':[w,h],'firmware':'2.12.5','status':'PASS' if all(checks.values()) else 'FAIL',
            'checks':checks,'source_sha256':hashlib.sha256((ROOT/('main.lua' if color else 'mono/switxt.lua')).read_bytes()).hexdigest()}
    (dest/'result.json').write_text(json.dumps(result,indent=2)+'\n')
    print(radio,result['status'],[k for k,v in checks.items() if not v],flush=True)
    return result

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--radios',nargs='+',choices=SIZES,default=list(SIZES));args=parser.parse_args()
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results=list(pool.map(run_one,args.radios))
    report={'status':'PASS' if all(r['status']=='PASS' for r in results) else 'FAIL','targets':results,
            'method':'Pinned official EdgeTX firmware DLLs, native logical-switch evaluation, unchanged production Lua, direct framebuffer capture',
            'limits':['Simulator firmware 2.12.5 only','Synthetic fixture models and logical-switch conditions','Not physical-radio validation','Observer invokes the unchanged production entry point and records drawing calls']}
    (RESULTS/'results.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['status']!='PASS': sys.exit(1)

if __name__=='__main__':main()
