/**
 * Sequential native component smoke, NOT useVoiceMode acceptance.
 * No microphone, endpointer, chat history, streamed playback or re-listen.
 */
export interface PipelinePort {
  prepare(): Promise<void>;
  transcribe(): Promise<string>;
  generate(text: string): Promise<string>;
  speak(text: string): Promise<void>;
  release(): Promise<void>;
}

export async function runFreedomPipeline(
  port: PipelinePort,
  cancelled: () => boolean = () => false,
  expectedWords: readonly string[] = ['cook', 'dinner'],
) {
  const check = () => {
    if (cancelled()) {
      throw new Error('pipeline cancelled');
    }
  };
  try {
    check();
    await port.prepare();
    check();
    const transcript = (await port.transcribe()).trim();
    check();
    const words = new Set(transcript.toLowerCase().match(/[a-z]+/g) || []);
    if (
      expectedWords.length === 0 ||
      expectedWords.some(word => !words.has(word.toLowerCase()))
    ) {
      throw new Error(
        `Recorded-speech transcription missed expected ${expectedWords.join('/')} words`,
      );
    }
    const answer = (await port.generate(transcript)).trim();
    check();
    if (!answer) {
      throw new Error('Empty local model answer');
    }
    await port.speak(answer);
    check();
    return {transcript, answer, kind: 'sequential-component-smoke'};
  } finally {
    await port.release();
  }
}
