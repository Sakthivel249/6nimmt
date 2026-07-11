import wave
import struct
import math

def generate_wav(filename, duration, freq_func, sample_rate=44100):
    num_samples = int(duration * sample_rate)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            value = freq_func(t)
            # Apply a simple envelope to prevent clicking
            envelope = 1.0
            if i < 500:
                envelope = i / 500.0
            elif i > num_samples - 500:
                envelope = (num_samples - i) / 500.0
            
            value *= envelope
            
            packed_value = struct.pack('h', int(value * 32767.0))
            wav_file.writeframesraw(packed_value)

# Generate Button Click (High pitched blip)
def click_freq(t):
    freq = 800 + (t * -2000)
    return math.sin(2.0 * math.pi * freq * t) * 0.3

generate_wav('click.wav', 0.1, click_freq)

# Generate Card Place (Lower pitched thud/slide)
def card_place_freq(t):
    freq = 300 + (t * -1500)
    return (math.sin(2.0 * math.pi * freq * t) * 0.4) + (math.sin(2.0 * math.pi * (freq/2) * t) * 0.2)

generate_wav('card_place.wav', 0.15, card_place_freq)

# Generate BGM (Simple retro repeating loop)
def bgm_freq(t):
    # Simple arpeggio loop: C4, E4, G4, C5 (261.63, 329.63, 392.00, 523.25)
    notes = [261.63, 329.63, 392.00, 523.25, 392.00, 329.63]
    bpm = 120
    beat_duration = 60.0 / bpm
    note_duration = beat_duration / 2
    
    cycle_time = note_duration * len(notes)
    t_in_cycle = t % cycle_time
    note_idx = int(t_in_cycle / note_duration)
    current_freq = notes[note_idx]
    
    # Add some basic synth characteristics (square-ish wave by using sign)
    val = math.sin(2.0 * math.pi * current_freq * t)
    val = 1.0 if val > 0 else -1.0
    
    # Add a soft pad sine wave for background
    pad = math.sin(2.0 * math.pi * (current_freq / 2) * t)
    
    return (val * 0.1) + (pad * 0.1)

# Generate a 12 second BGM loop
generate_wav('bgm.wav', 12.0, bgm_freq)

print("Audio files generated successfully.")
