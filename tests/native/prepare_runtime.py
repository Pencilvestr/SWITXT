"""Extract the fingerprint-pinned official simulator package without installing it."""
from pathlib import Path
import argparse, hashlib, json, shutil, subprocess, urllib.request, zipfile

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--archive',type=Path,help='Existing official ZIP; otherwise download it')
    parser.add_argument('--extractor',required=True,help='Full 7-Zip executable with NSIS support')
    args=parser.parse_args()
    manifest=json.loads((HERE/'binding-manifest.json').read_text())
    runtime=ROOT/'work/native-runtime'
    def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
    if all((runtime/'bin'/name).is_file() and sha(runtime/'bin'/name)==value for name,value in manifest['sha256'].items()):
        print('Pinned runtime already verified.');return
    cache=ROOT/'work/native-downloads';cache.mkdir(parents=True,exist_ok=True)
    archive=args.archive or cache/'edgetx-cpn-win64-v2.12.5.zip'
    if not archive.exists():
        assert manifest['source_url']=='https://github.com/EdgeTX/edgetx/releases/download/v2.12.5/edgetx-cpn-win64-v2.12.5.zip'
        urllib.request.urlretrieve(manifest['source_url'],archive)
    assert sha(archive)==manifest['archive_sha256'],'Official archive fingerprint mismatch'
    installer=cache/'companion-windows-2.12.5.exe'
    with zipfile.ZipFile(archive) as z:
        with z.open(installer.name) as source,installer.open('wb') as target: shutil.copyfileobj(source,target)
    subprocess.run([args.extractor,'x',str(installer),'-o'+str(runtime),'-y']+['bin\\'+name for name in manifest['sha256']],check=True)
    for name,value in manifest['sha256'].items():
        assert sha(runtime/'bin'/name)==value,'Extracted fingerprint mismatch: '+name
    print('Official runtime extracted and verified; installer was not executed.')

if __name__=='__main__':main()
