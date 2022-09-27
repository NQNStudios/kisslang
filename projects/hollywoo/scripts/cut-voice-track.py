#! /usr/bin/env python
# pip install -r requirements.txt
usage = 'python cut-voice-track.py <wav timestamp json> <?wav filename>'

from imports import *
import util
import string
from os.path import exists
from os import system
system('color')

json_filename = util.arg(1, usage)
default_wav_name = json_filename.replace('_4000.json', '')
wav_filename = util.arg(2, usage, default_wav_name)

cutter = util.AudioCutter(wav_filename, json_filename)

def new_wav_file():
    suffix = "0"
    new_wav = wav_filename.replace(".wav", f"-cut{suffix}.wav")
    while exists(new_wav):
        new_suffix = str(int(suffix) + 1)
        new_wav = new_wav.replace(f"-cut{suffix}.wav", f"-cut{new_suffix}.wav")
        suffix = new_suffix
    return new_wav

def save():
    new_wav = new_wav_file()
    cutter.save_and_quit(new_wav)

def process_chunk(audio_guess, possible_sections):
    num_takes = len(possible_sections)
    if num_takes > 36:
        print('\033[31m' + audio_guess + '\033[0m')
        print('\033[31m' + f'Warning! {num_takes} is too many! Skipping' + '\033[0m')
        return
    assert num_takes <= 36, "I didn't plan for this many takes of any line"
    alphabet_takes = 0
    if num_takes > 10:
        alphabet_takes = num_takes - 10
        num_takes = 10
    takes = '/'.join([str(num) for num in range(num_takes)])
    if alphabet_takes > 0:
        takes += '/' + '/'.join(string.ascii_uppercase[:alphabet_takes])

    def start_and_end(choice):
        take_num = -1
        if choice in string.ascii_uppercase:
            take_num = 10 + string.ascii_uppercase.index(choice)
        else:
            take_num = int(choice)
        take_info = possible_sections[take_num]
        start = take_info['start']
        end = take_info['end']
        return start, end
    
    print('\033[31m' + audio_guess + '\033[0m')
    print(f'{takes}/u({takes}/*)/d/f/n/h/q')
    while True:
        choice = getch()
        if choice == 'h':
            print(f'{num_takes} takes.')
            print(f'{takes} - play a take')
            print(f'u + {takes} - use a take.')
            print(f'u + * -  use all takes as alts.')
            print('f - search ahead for a word or phrase')
            print('n - repeat a search.')
            print('d - discard this snippet.')
            print('q - save and quit')
        elif choice == 'd':
            break
        elif choice != '/' and choice in takes:
            start, end = start_and_end(choice)
            cutter.play_audio(start, end)
        elif choice == 'f':
            cutter.search()
            break
        elif choice == 'n':
            cutter.repeat_search()
            break
        elif choice == 'q':
            save()
        elif choice == 'u':
            choice = getch()
            choices = takes.split('/')
            if choice == '*':
                # use all the takes
                print('using all')
                line_with_alts = {}
                start, end = start_and_end(choices[0])
                length = end - start
                line_with_alts['start'] = cutter.current_sec
                line_with_alts['end'] = cutter.current_sec + length
                cutter.take_audio(audio_guess, line_with_alts, start, end)
                alts = []
                for choice in choices[1:]:
                    start, end = start_and_end(choices[0])
                    length = end - start
                    alts.append({'start': cutter.current_sec, 'end': cutter.current_sec + length})
                    line_with_alts['alts'] = alts
                    cutter.take_audio(audio_guess, line_with_alts, start, end)
                break
            elif choice != '/' and choice in takes:
                start, end = start_and_end(choices[0])
                length = end - start
                info = {
                    'start': cutter.current_sec,
                    'end': cutter.current_sec + length
                }
                cutter.take_audio(audio_guess, info, start, end)
                break
            else:
                print(f'{choice} is not a valid take to use')

        else:
            print(f'{choice} is not a valid option')

cutter.process_audio(process_chunk, new_wav_file())