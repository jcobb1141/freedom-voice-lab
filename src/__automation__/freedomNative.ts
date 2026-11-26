import * as RNFS from '@dr.pogodin/react-native-fs';
import Speech from '@pocketpalai/react-native-speech';
import {initLlama, type LlamaContext} from 'llama.rn';

import {whisperAsrEngine} from '../services/asr';
import {getNeuralEngine, ttsRuntime} from '../services/tts';
import {FREEDOM_LAB_SYSTEM_PROMPT} from '../freedom/labCharacter';
import {runFreedomPipeline} from './freedomPipeline';

let running = false;

export async function runFreedomNative(): Promise<void> {
  if (running) {
    throw new Error('Freedom smoke already running');
  }
  running = true;
  const status = `${RNFS.DocumentDirectoryPath}/freedom-result.json`;
  let context: LlamaContext | undefined;
  let starts = 0;
  let finishes = 0;
  const started = Date.now();
  const startSub = Speech.onStart(() => {
    starts++;
  });
  const finishSub = Speech.onFinish(() => {
    finishes++;
  });
  const engine = getNeuralEngine('kokoro');
  try {
    await RNFS.writeFile(
      status,
      JSON.stringify({marker: 'FREEDOM_NATIVE_PIPELINE_V1', state: 'running'}),
      'utf8',
    );
    const result = await runFreedomPipeline({
      async prepare() {
        if (!(await whisperAsrEngine.isInstalled('base'))) {
          await whisperAsrEngine.downloadModel('base');
        }
        await whisperAsrEngine.preload('base');
        if (!(await engine.isInstalled())) {
          await engine.downloadModel();
        }
        await ttsRuntime.acquire(engine, async () => {});
        context = await initLlama({
          model: `${RNFS.DocumentDirectoryPath}/freedom-model.gguf`,
          n_ctx: 2048,
          n_gpu_layers: 0, // CPU simulator smoke; not a phone Metal benchmark.
        });
      },
      async transcribe() {
        const pcm = await RNFS.readFile(
          `${RNFS.DocumentDirectoryPath}/freedom-question.pcm`,
          'base64',
        );
        return (
          await whisperAsrEngine.transcribe(pcm, {tier: 'base', language: 'en'})
        ).text;
      },
      async generate(text) {
        const reply = await context!.completion({
          messages: [
            {role: 'system', content: FREEDOM_LAB_SYSTEM_PROMPT},
            {role: 'user', content: text},
          ],
          n_predict: 96,
          temperature: 0,
          enable_thinking: false,
        });
        return reply.text;
      },
      async speak(text) {
        const voice = (await engine.getVoices()).find(v => v.id === 'af_heart');
        if (!voice) {
          throw new Error('Kokoro af_heart voice missing');
        }
        await engine.play(text, voice);
        if (starts < 1 || finishes < 1) {
          throw new Error('No native playback start/finish callbacks');
        }
      },
      async release() {
        // Attempt every teardown even when one fails.
        const settled = await Promise.allSettled([
          whisperAsrEngine.release(),
          ttsRuntime.release(),
          context?.release(),
        ]);
        if (settled.some(item => item.status === 'rejected')) {
          throw new Error('Native teardown failed');
        }
      },
    });
    await RNFS.writeFile(
      status,
      JSON.stringify({
        ...result,
        state: 'done',
        starts,
        finishes,
        elapsedMs: Date.now() - started,
      }),
      'utf8',
    );
  } catch (error) {
    await RNFS.writeFile(
      status,
      JSON.stringify({state: 'error', error: String(error)}),
      'utf8',
    );
  } finally {
    startSub.remove();
    finishSub.remove();
    running = false;
  }
}
