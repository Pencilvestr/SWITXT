"""Isolated native EdgeTX framebuffer tests, adapted from ELRS SignalView.

See ADAPTER-LICENSE.txt. Exact MSVC x64/Qt6 ABI; refuse unpinned binaries.
No desktop capture, OS input, personal models, or installed-app changes.
"""
from pathlib import Path
import argparse, ctypes as C, hashlib, json, os, shutil, sys, time, traceback
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
SIZES={'tx16smk3':(800,480),'tx16s':(480,272),'tx15':(480,320),'nv14':(320,480),'pa01':(320,240),
       'boxer':(128,64),'pocket':(128,64),'x9d+2019':(212,64)}
P=C.c_void_p

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--radio',choices=SIZES,required=True)
    parser.add_argument('--bootstrap',action='store_true')
    args=parser.parse_args()
    w,h=SIZES[args.radio]; color=h>64
    run=ROOT/'work/native-results'/args.radio
    sd,settings=run/'sd',run/'settings'
    sd.mkdir(parents=True,exist_ok=True);settings.mkdir(exist_ok=True)
    manifest=json.loads((HERE/'binding-manifest.json').read_text())
    bindir=Path(os.environ.get('SWITXT_RUNTIME',str(ROOT/manifest['library_directory'])))
    required=['Qt6Core.dll','Qt6Gui.dll','Qt6Multimedia.dll','Qt6Network.dll','Qt6Widgets.dll','SDL2.dll',f'libedgetx-{args.radio}-simulator.dll']
    for name in required:
        assert hashlib.sha256((bindir/name).read_bytes()).hexdigest()==manifest['sha256'][name],f'Unreviewed binary: {name}'
    if color:
        shutil.copytree(HERE/'fixtures'/args.radio,settings,dirs_exist_ok=True)
        model=settings/'MODELS/model1.yml'
        content=model.read_text()
        entries=''
        for index,label,shade in [(1,'ARMED','0x00C000'),(4,'DISARMED','0xE00000'),(7,'MOTOR OFF','0xC09000')]:
            entries+=f'                     {index}:\n                        type: String\n                        value:\n                           stringValue: "{label}"\n'
            entries+=f'                     {index+1}:\n                        type: Color\n                        value:\n                           color: {shade}\n'
        content=content.replace('               widgetData: \n','               widgetData: \n                  options:\n'+entries,1)
        model.write_text(content)
        dest=sd/'WIDGETS/SWITXT';dest.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/'main.lua',dest/'main.lua')
        dest=sd/'WIDGETS/LabTest';dest.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(HERE/'observer.lua',dest/'main.lua')
    else:
        if not args.bootstrap:
            shutil.copytree(HERE/'fixtures'/args.radio,settings,dirs_exist_ok=True)
        dest=sd/'SCRIPTS/TELEMETRY';dest.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/'mono/switxt.lua',dest/'switxt.lua')
        shutil.copyfile(HERE/'observer.lua',dest/'lab.lua')
    phasefile=sd/'phase.lua'
    def phase(identifier,states,**flags):
        value='return {id='+str(identifier)+',states={'+','.join(str(v).lower() for v in states)+'}'
        for name,state in flags.items(): value+=','+name+'='+str(state).lower()
        phasefile.write_text(value+'}\n')
    phase(0,[False]*3)
    dll_handle=os.add_dll_directory(str(bindir))
    core=C.CDLL(str(bindir/'Qt6Core.dll'))
    sim=C.CDLL(str(bindir/f'libedgetx-{args.radio}-simulator.dll'))
    def fn(dll,name,params,ret=None):
        f=getattr(dll,name);f.argtypes=params;f.restype=ret;return f
    application=C.create_string_buffer(65536)
    argc=C.c_int(1);argument=C.create_string_buffer(b'SWITXT-native-test')
    argv=(C.c_char_p*2)(C.cast(argument,C.c_char_p),None)
    fn(core,'??0QCoreApplication@@QEAA@AEAHPEAPEADH@Z',[P,C.POINTER(C.c_int),C.POINTER(C.c_char_p),C.c_int])(application,C.byref(argc),argv,0x060000)
    factory=fn(sim,'registerSimu',[],P)()
    vtable=C.cast(factory,C.POINTER(P))[0]
    obj=C.CFUNCTYPE(P,P)(C.cast(vtable,C.POINTER(P))[3])(factory)
    strings=[]
    def qstring(value):
        buf=C.create_string_buffer(64)
        fn(core,'??0QString@@QEAA@PEBD@Z',[P,C.c_char_p])(buf,str(value).encode())
        strings.append(buf);return buf
    fn(sim,'?setSdPath@OpenTxSimulator@@UEAAXAEBVQString@@0@Z',[P,P,P])(obj,qstring(sd),qstring(settings))
    fn(sim,'?init@OpenTxSimulator@@UEAAXXZ',[P])(obj)
    connection=C.create_string_buffer(64)
    fn(core,'?connect@QObject@@SA?AVConnection@QMetaObject@@PEBV1@PEBD01W4ConnectionType@Qt@@@Z',
       [P,P,C.c_char_p,P,C.c_char_p,C.c_int],P)(connection,obj,b'2lcdChange(bool)',obj,b'1lcdFlushed()',0)
    fn(sim,'?start@OpenTxSimulator@@UEAAXPEBD_N@Z',[P,C.c_char_p,C.c_bool])(obj,None,True)
    process=fn(core,'?processEvents@QCoreApplication@@SAXV?$QFlags@W4ProcessEventsFlag@QEventLoop@@@@@Z',[C.c_int])
    lcd=fn(sim,'?getLcd@OpenTxSimulator@@UEAAPEAEXZ',[P],P)
    key=fn(sim,'?setKey@OpenTxSimulator@@UEAAXE_N@Z',[P,C.c_uint8,C.c_bool])
    def wait(seconds):
        end=time.monotonic()+seconds
        while time.monotonic()<end: process(0);time.sleep(.005)
    def press(index,duration=.12):
        key(obj,index,True);wait(duration);key(obj,index,False);wait(.3)
    def capture(name):
        if color:
            raw=C.string_at(lcd(obj),w*h*2)
            im=Image.frombytes('RGB',(w,h),raw,'raw','BGR;16')
        elif w==212:
            # 212x64 displays store two vertical pixels per byte, four bits each.
            raw=C.string_at(lcd(obj),w*h//2)
            im=Image.new('L',(w,h),255)
            im.putdata([255-17*((raw[x+(y//2)*w]>>(4*(y%2)))&15) for y in range(h) for x in range(w)])
        else:
            raw=C.string_at(lcd(obj),w*h//8)
            im=Image.new('L',(w,h),255)
            im.putdata([0 if raw[x+(y//8)*w] & (1<<(y%8)) else 255 for y in range(h) for x in range(w)])
        im.save(run/(name+'.png'))
        print('CAPTURE|'+name,flush=True)
    exit_code=0
    try:
        wait(5)
        if args.bootstrap:
            press(2);wait(3);capture('bootstrap')
        else:
            if not color:
                # Match the firmware's per-family navigation mapping.
                press(3 if args.radio=='x9d+2019' else 12);wait(1)
            cases=[(1,'armed',[True,False,False],{}),(2,'disarmed',[False,True,False],{}),
                   (3,'motor-off',[False,False,True],{}),(4,'priority',[True,True,True],{}),
                   (5,'blank',[False,False,False],{})]
            if color: cases += [(6,'small',[True,False,False],{'small':True}),
                                (7,'long-small',[True,False,False],{'small':True,'long':True}),
                                (8,'normal',[True,False,False],{})]
            for number,name,states,flags in cases:
                phase(number,states,**flags);wait(1);capture(name)
            if color:
                if args.radio=='pa01': press(2,1.1);press(2);press(2)
                else:
                    touch=fn(sim,'?touchEvent@OpenTxSimulator@@UEAAXHHH@Z',[P,C.c_int,C.c_int,C.c_int])
                    def tap(x,y,duration=.12):
                        touch(obj,1,int(x),int(y));wait(duration);touch(obj,0,int(x),int(y));wait(.4)
                    tap(w/2,h/2,1.1);tap(w/2,h/2-5)
                phase(9,[True,False,False]);wait(1);capture('fullscreen')
                phase(10,[False,False,False]);wait(1);capture('fullscreen-blank')
                press(1,1.1);phase(11,[False,True,False]);wait(1);capture('returned')
    except Exception:
        traceback.print_exc()
        exit_code=1
    finally:
        fn(sim,'?stop@OpenTxSimulator@@UEAAXXZ',[P])(obj)
        sys.stdout.flush();sys.stderr.flush();os._exit(exit_code)

if __name__=='__main__': main()
