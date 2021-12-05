# pip install requests
# pip install volk
# pip install scipy
import wave
import json
import sys
import os
import requests
from zipfile import ZipFile
from scipy.io import wavfile

from vosk import Model, KaldiRecognizer

model_name = "vosk-model-small-en-us-0.15"
# model_name = "vosk-model-en-us-0.22" # bigger model. So far, the small one works pretty good.

model_path = f"models/{model_name}"
model_zip_path = f"{model_path}.zip"
model_url = f"http://alphacephei.com/vosk/{model_zip_path}"

# Download the model if it doesn't exist
os.makedirs('models', exist_ok=True)
if not os.path.exists(model_path):
    with open(model_zip_path, 'wb') as f:
        response = requests.get(model_url)
        f.write(response.content)
    with ZipFile(model_zip_path, "r") as zip_file:
        zip_file.extractall('models')

audio_filename = sys.argv[1] if len(sys.argv) > 1 else input("mono-track wav filename? ")
wf = wave.open(audio_filename, "rb")

model = Model(model_path)
rec = KaldiRecognizer(model, wf.getframerate())
rec.SetWords(True)

frames = 4000
while True:
    # Mix channels together if the input is stereo
    if wf.getnchannels() == 2:
        wf.close()
        mono_filename = '.'.join(audio_filename.split('.')[:-1]) + '_mono.wav'
        fs, data = wavfile.read(audio_filename)
        wavfile.write(mono_filename, fs, data[:, 0])
        wf = wave.open(mono_filename, 'rb')

    wf.rewind()
    results = []
    def filter_result(result):
        result = json.loads(result)
        if len(result) != 1:
            results.append(result)

    while True:
        data = wf.readframes(frames)
        if len(data) == 0:
            break
        if rec.AcceptWaveform(data):
            filter_result(rec.Result())
    filter_result(rec.FinalResult())
    
    with open(f"{audio_filename}_{frames}.json", "w") as f:
        lines = {}
        for sentence in results:
            words = sentence['result']
            text = sentence['text']
            # Account for duplicate sentences:
            if not text in lines:
                lines[text] = []
            lines[text].append({'start': words[0]['start'], 'end': words[-1]['end']})
            print(f'{text}: {words[0]["start"]} {words[-1]["end"]}')
        json.dump(lines, f)

    frames = int(input(f"Try different frames num? (was {frames}): "))
