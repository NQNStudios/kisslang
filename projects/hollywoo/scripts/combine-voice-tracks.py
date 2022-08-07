#! /usr/bin/env python
# pip install -r requirements.txt
usage = 'python combine--json.py <cut-voice-track json files...>'

import util
import json
import sys
from numpy import vstack
from scipy.io import wavfile
import wave
import string
try:
    from getch import getch
except:
    from msvcrt import getwch as getch
from os.path import exists
from os import system
system('color')

json_filenames = util.args(1, usage)
if '-cut0.json' not in json_filenames[0]:
    print('failing to generate a combined filename because args do not start with cut0 file')
    sys.exit(1)
new_filename = json_filenames[0].replace("-cut0.json", "-combined")

new_data=None
new_json=None
framerate=None

file_start_time = 0
def offset(element):
    obj = {
        "start": element["start"] + file_start_time,
        "end": element["end"] + file_start_time
    }
    if "alts" in element:
        obj["alts"] = list(map(offset, element["alts"]))
    return obj

def combine(element1, element2):
    alts = []
    if "alts" in element1:
        alts = element1["alts"]
    alts.append({
        "start": element2["start"],
        "end": element2["end"]
    })
    alts = alts + element2["alts"]
    return {
        "start": element1["start"],
        "end": element1["end"],
        "alts": alts
    }

for json_filename in json_filenames:
    timestamps = {}
    with open(json_filename, 'r') as f:
        timestamps = json.load(f)

    wav_filename = json_filename.replace(".json", ".wav")
    wav = None
    with open(wav_filename, 'rb') as f:
        wav = wave.open(f)

    nchannels, sampwidth, framerate, nframes, comptype, compname = wav.getparams()

    _, data = wavfile.read(wav_filename)

    if new_data is None:
        new_data = data
        new_json = timestamps
    else:
        new_data = vstack((new_data, data))
        for key, element in timestamps.items():
            element = offset(element)
            if key in new_json:
                combined = combine(new_json[key], element)
                new_json[key] = combined
            else:
                new_json[key] = element

    # Collect the new time offset for the next file's timestamps
    for _, element in timestamps.items():
        end = element["end"]
        if "alts" in element:
            end = element["alts"][-1]["end"]
        if end > file_start_time:
            file_start_time = end

new_wav = new_filename + ".wav"
wavfile.write(new_wav, framerate, new_data)
with open(new_wav.replace(".wav", ".json"), 'w') as f:
    json.dump(new_json, f)
sys.exit(0)