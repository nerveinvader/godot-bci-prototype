"""
EEG to WebSocket Streamer (server)
--------------------------------
 Reads an open EEG file, extract alpha-band amplitude,
 Sends each value to any clients that connects (e.g. Godot).

 Works on Python 3.10+

 How to Run:
 Start this then your client.
"""

import asyncio
import json
import time
import mne
import websockets # Note: Not a full server / just a client lib
import numpy as np

###
## LOAD PARAMETERS
SUBJECT_ID = 2 # PhysioNet dataset ID and subject/run to download
RUN_LIST = [4] # run 4 = motor-imagery right / left hand
F_LOW, F_HIGH = 8.0, 13.0 # alpha-band limits

WS_URL = "ws://localhost:8765" # Websocker endpoint (same as GODOT)
SERVER_HOST = "localhost"
SERVER_PORT = 8765
SEND_FPS = 30 # send 30 samples per second

###
## LOAD EEG DATA
edf_path = mne.datasets.eegbci.load_data(SUBJECT_ID, RUN_LIST)[0]
raw = mne.io.read_raw_edf(edf_path, preload=True, verbose=False)

# Pre process data
# 1. re reference if needed
# 2. bandpass filter to isolate alpha band
raw.filter(F_LOW, F_HIGH, picks="eeg", verbose=False)

# pick one channel (preferred Cz)
ch_names = raw.info["ch_names"] # list of names
preferred = [name for name in ch_names if "Cz" in name]
if preferred:
    pick = preferred[0]
else: # fallback to the first EEG channel
    pick = mne.pick_types(raw.info, eeg=True)[0] # return index
    pick = ch_names[pick] # convert to name
print(f"Using Channel: {pick}")
# then, faltten to 1-D numpy
eeg_signal = raw.get_data(picks=pick)[0] # shape(1, n_samples)

dt = 1.0/SEND_FPS # seconds between packet

###
## WEBSOCKET SERVER
async def stream(websocket):
    print("Client Connected: ", websocket.remote_address)
    for sample in eeg_signal:
        alpha_amp = float(abs(sample))
        payload = json.dumps({"alpha": alpha_amp})
        await websocket.send(payload)
        await asyncio.sleep(dt)
    await websocket.close()
    print("Stream Finished, Connection Closed.")

async def main():
    async with websockets.serve(stream, SERVER_HOST, SERVER_PORT):
        print(f"SERVER up at ws://{SERVER_HOST}:{SERVER_PORT}")
        await asyncio.Future() # run forever

if __name__ == "__main__":
    asyncio.run(main())
