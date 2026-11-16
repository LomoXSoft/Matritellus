# makes godot/assets/audio/ninos_jugando.ogg from BigSoundBank #1082 (CC0, Joseph Sardin): mono, high-passed, the
# loud stretch 44-72 s left out, two pieces joined and looped with crossfades, levelled
import subprocess, sys, numpy as np
src, out = sys.argv[1], sys.argv[2]
SR = 44100
raw = subprocess.run(['ffmpeg','-v','error','-i',src,'-af','highpass=f=160','-ac','1','-ar',str(SR),'-f','f32le','-'],capture_output=True).stdout
x = np.frombuffer(raw, np.float32).astype(np.float64)
a = x[int(73*SR):int(144.5*SR)]
b = x[int(0.5*SR):int(43.5*SR)]
F = int(2.0*SR)
ramp = np.linspace(0, 1, F)
def join(p, q):
    return np.concatenate([p[:-F], p[-F:]*(1-ramp) + q[:F]*ramp, q[F:]])
y = join(a, b)
# the loop: its end fades into its own beginning
y = np.concatenate([y[F:-F], y[-F:]*(1-ramp) + y[:F]*ramp])
rms = np.sqrt(np.mean(y**2))
y = y * (10**(-20/20) / rms)
peak = np.max(np.abs(y))
if peak > 0.95:
    y = y * 0.95 / peak
pcm = (np.clip(y, -1, 1) * 32767).astype('<i2').tobytes()
subprocess.run(['ffmpeg','-v','error','-y','-f','s16le','-ar',str(SR),'-ac','1','-i','-','-c:a','libvorbis','-q:a','4',out],input=pcm,check=True)
print('seconds %.1f  rms -20 dB  peak %.2f' % (len(y)/SR, min(peak, 0.95)))
