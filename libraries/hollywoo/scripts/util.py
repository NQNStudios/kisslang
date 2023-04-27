from imports import *
import numpy as np

def arg(num, usage, default=None):
    val = ''
    if len(sys.argv) > num:
        val = sys.argv[num]
    else:
        if default != None:
            return default
        raise ValueError(usage)
    return val

def args(starting_num, usage, default=None):
    l = []
    if len(sys.argv) > starting_num:
        l = sys.argv[starting_num:]
    else:
        if default != None:
            return default
        raise ValueError(usage)
    return l

class AudioCutter:
    def __init__(self, wav_file, json_file):
        # Store a wav file's sound data and json data representing tagged chunks of audio in the wav
        with open(json_file, 'r') as f:
            self.json_info = json.load(f)
        
        with open(wav_file, 'rb') as f:
            self.wav = wave.open(f)

        self.nchannels, self.sampwidth, self.framerate, self.nframes, self.comptype, self.compname = self.wav.getparams()
        self.rate, self.data = wavfile.read(wav_file)
        
        # Accumulate new sound data cut from the original, along with new related json data
        self.new_data = self.data[0:1]
        self.new_json_info = {}

        # State of a search through the json/wav file:
        self.current_sec = 0
        self.searching_for = None
        self.last_search = None

    def save_and_quit(self, new_wav_file):
        wavfile.write(new_wav_file, self.framerate, self.new_data)
        with open(new_wav_file.replace(".wav", ".json"), 'w') as f:
            json.dump(self.new_json_info, f)
        sys.exit(0)

    def audio_and_length(self, start, end):
        start_frame = int(start * self.framerate)
        end_frame = int(end * self.framerate)
        return self.data[start_frame:end_frame], end - start

    def take_audio(self, tag, info, start, end):
        audio, length = self.audio_and_length(start, end)
        self.new_data = vstack((self.new_data, audio))
        self.current_sec += length
        self.new_json_info[tag] = info

    def add_silence(self, seconds):
        nframes = int(seconds * self.rate)
        shape = self.new_data.shape
        shape = (nframes,) + shape[1:]
        self.new_data = vstack((self.new_data, np.zeros(shape, self.new_data.dtype)))

    def play_audio(self, start, end):
        audio, _ = self.audio_and_length(start, end)
        play_buffer(audio, self.nchannels, self.sampwidth, self.framerate)

    def search(self):
        phrase = input("phrase (lower-case) to search for?")
        self.last_search = phrase
        self.searching_for = phrase
    
    def repeat_search(self):
        self.searching_for = self.last_search

    def process_audio(self, chunk_processor, new_wav_file):
        for (audio_tag, chunk_info) in self.json_info.items():
            # When the AudioCutter is searching for a phrase, skip all audio tags that don't match
            if self.searching_for != None:
                if self.searching_for in audio_tag:
                    self.searching_for = None
                else:
                    continue
            
            chunk_processor(audio_tag, chunk_info)
        
        if self.searching_for != None:
            print(f"{self.searching_for} not found")
        
        self.save_and_quit(new_wav_file)


    



