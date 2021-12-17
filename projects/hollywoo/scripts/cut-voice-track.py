#! /usr/bin/env python
# pip install -r requirements.txt
usage = 'python cut-voice-track.py <?wav timestamp json> <?wav filename>'

import util
import json
import sys
from numpy import vstack
from scipy.io import wavfile
from simpleaudio import play_buffer
import wave
import string
try:
    from getch import getch
except:
    from msvcrt import getwch as getch
from os.path import exists
from os import system
system('color')

json_filename = util.arg(1, usage)
default_wav_name = json_filename.replace('_4000.json', '')
wav_filename = util.arg(2, usage, default_wav_name)

timestamps = {}
with open(json_filename, 'r') as f:
    timestamps = json.load(f)

wav = None
with open(wav_filename, 'rb') as f:
    wav = wave.open(f)

nchannels, sampwidth, framerate, nframes, comptype, compname = wav.getparams()

_, data = wavfile.read(wav_filename)

new_data = data[0:1]
new_json = {}

def save():
    suffix = "0"
    new_wav = wav_filename.replace(".wav", f"-cut{suffix}.wav")
    while exists(new_wav):
        new_suffix = str(int(suffix) + 1)
        new_wav = new_wav.replace(f"-cut{suffix}.wav", f"-cut{new_suffix}.wav")
        suffix = new_suffix
    wavfile.write(new_wav, framerate, new_data)
    with open(new_wav.replace(".wav", ".json"), 'w') as f:
        json.dump(new_json, f)
    sys.exit(0)

current_sec = 0
searching_for = None
last_search = None
for (audio_guess, possible_sections) in timestamps.items():
    if searching_for != None:
        if searching_for in audio_guess:
            searching_for = None
        else:
            continue

    num_takes = len(possible_sections)
    if num_takes > 36:
        print('\033[31m' + audio_guess + '\033[0m')
        print('\033[31m' + f'Warning! {num_takes} is too many! Skipping' + '\033[0m')
        continue
    assert num_takes <= 36, "I didn't plan for this many takes of any line"
    alphabet_takes = 0
    if num_takes > 10:
        alphabet_takes = num_takes - 10
        num_takes = 10
    takes = '/'.join([str(num) for num in range(num_takes)])
    if alphabet_takes > 0:
        takes += '/' + '/'.join(string.ascii_uppercase[:alphabet_takes])

    def audio_and_length(choice):
        take_num = -1
        if choice in string.ascii_uppercase:
            take_num = 10 + string.ascii_uppercase.index(choice)
        else:
            take_num = int(choice)
        take_info = possible_sections[take_num]
        start = take_info['start']
        end = take_info['end']
        start_frame = int(start * framerate)
        end_frame = int(end * framerate)
        return data[start_frame:end_frame], end - start
    
    print('\033[31m' + audio_guess + '\033[0m')
    print(f'{takes}/u({takes})/d/f/n/h/q')
    while True:
        choice = getch()
        if choice == 'h':
            print(f'{num_takes} takes. Type {takes} to play one. Type u + {takes} to use one of them. Type f to search ahead for a word or phrase. Type n to repeat a search. Type d to discard this snippet. Type q to quit')
        elif choice == 'd':
            break
        elif choice != '/' and choice in takes:
            audio, _ = audio_and_length(choice)
            play_buffer(audio, nchannels, sampwidth, framerate)
        elif choice == 'f':
            phrase = input("phrase (lower-case) to search for?")
            last_search = phrase
            searching_for = phrase
            break
        elif choice == 'n':
            searching_for = last_search
            break
        elif choice == 'q':
            save()
        elif choice == 'u':
            choice = getch()
            if choice != '/' and choice in takes:
                audio, length = audio_and_length(choice)
                new_json[audio_guess] = {
                    'start': current_sec,
                    'end': current_sec + length
                }
                new_data = vstack((new_data, audio))
                current_sec += length
                break
            else:
                print(f'{choice} is not a valid take to use')

        else:
            print(f'{choice} is not a valid option')

if searching_for != None:
    print(f"{searching_for} not found")

save()