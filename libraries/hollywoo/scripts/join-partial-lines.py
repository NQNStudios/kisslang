#! /usr/bin/env python
# pip install -r requirements.txt
usage = 'python join-partial-lines.py <cut json> <?wav filename>'

from imports import *
import util
from time import sleep
import string
from os.path import exists
from os import system
system('color')

json_filename = util.arg(1, usage)
default_wav_name = json_filename.replace('.json', '.wav')
wav_filename = util.arg(2, usage, default_wav_name)

cutter = util.AudioCutter(wav_filename, json_filename)

def new_wav_filename():
    suffix = "0"
    new_wav = wav_filename.replace(".wav", f"-joined{suffix}.wav")
    while exists(new_wav):
        new_suffix = str(int(suffix) + 1)
        new_wav = new_wav.replace(f"-joined{suffix}.wav", f"-joined{new_suffix}.wav")
        suffix = new_suffix
    return new_wav


def save():
    cutter.save_and_quit(new_wav_filename())

joining_with_guess = ""
joining_with = None
delay_time = 0.5

def process_chunk(audio_guess, timestamp):
    global joining_with_guess
    global joining_with
    global delay_time
    if joining_with != None:
        print(f'Joining onto: \033[92m{joining_with_guess}\033[0m')
    print('\033[31m' + audio_guess + '\033[0m')
    usage = f'u/d/j/p/t/f/n/q/h' 
    print(usage)
    if 'alts' in timestamp:
        print('join-partial-lines cannot join alts. skipping')
        length = timestamp['end'] - timestamp['start']
        adjusted = {'start': cutter.current_sec, 'end': cutter.current_sec + length, 'alts': []}
        cutter.take_audio(audio_guess, adjusted, timestamp['start'], timestamp['end'])
        for alt in timestamp['alts']:
            length = alt['end'] - alt['start']
            adjusted['alts'].append({'start': cutter.current_sec, 'end': cutter.current_sec + length})
            cutter.take_audio(audio_guess, adjusted, alt['start'], alt['end'])
        return

    while True:
        choice = getch()
        if choice == 'u':
            cutter.take_audio(audio_guess, timestamp, timestamp['start'], timestamp['end'])
        elif choice == 'd':
            break
        elif choice == 'j':
            if joining_with == None:
                joining_with_guess = audio_guess
                joining_with = timestamp
            else:
                # do the join
                joined_guess = joining_with_guess + " " + audio_guess
                full_timestamp = {
                    'start': cutter.current_sec,
                    'end': cutter.current_sec + (joining_with['end'] - joining_with['start']) + delay_time + (timestamp['end'] - timestamp['start'])
                }
                cutter.take_audio(joined_guess, full_timestamp, joining_with['start'], joining_with['end'])
                cutter.add_silence(delay_time)
                cutter.take_audio(joined_guess, full_timestamp, timestamp['start'], timestamp['end'])
                # clear the joining part
                joining_with_guess = ""
                joining_with = None
            break
        elif choice == 'f':
            cutter.search()
            break
        elif choice == 'n':
            cutter.repeat_search()
            break
        elif choice == 'q':
            save()
        elif choice == 'p':
            cutter.play_audio(joining_with['start'], joining_with['end'])
            sleep(joining_with['end'] - joining_with['start'])
            sleep(delay_time)
            cutter.play_audio(timestamp['start'], timestamp['end'])
        elif choice == 't':
            delay_time = float(input("seconds to pause between parts? "))
            print(usage)

        elif choice == 'h':
            print('u - use this line as-is')
            if joining_with != None:
                print(f'j - join this line with \033[92m{joining_with_guess}\033[0m')
            else:
                print('j - join this line with another line')
            print(f't - set the delay time (currently {delay_time}')
            print('p - play this line as if joined')
            print('f - search ahead for a word or phrase')
            print('n - repeat a search.')
            print('d - discard this line')
            print('q - save and quit')

cutter.process_audio(process_chunk, new_wav_filename())