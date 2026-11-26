import {runFreedomPipeline, type PipelinePort} from '../freedomPipeline';

function port(): jest.Mocked<PipelinePort> {
  return {
    prepare: jest.fn().mockResolvedValue(undefined),
    transcribe: jest.fn().mockResolvedValue('What should I cook for dinner?'),
    generate: jest.fn().mockResolvedValue('Try pasta.'),
    speak: jest.fn().mockResolvedValue(undefined),
    release: jest.fn().mockResolvedValue(undefined),
  };
}

describe('Freedom sequential smoke contract (mocked components)', () => {
  it('accepts explicit human-fixture words without changing production engines', async () => {
    const p = port();
    p.transcribe.mockResolvedValue('A golden fortune and a happy life.');
    await expect(
      runFreedomPipeline(p, undefined, ['golden', 'fortune', 'happy']),
    ).resolves.toMatchObject({
      transcript: 'A golden fortune and a happy life.',
    });
    expect(p.generate).toHaveBeenCalledWith(
      'A golden fortune and a happy life.',
    );
  });
  it('does not allow an empty expectation list to bypass transcription checks', async () => {
    const p = port();
    await expect(runFreedomPipeline(p, undefined, [])).rejects.toThrow(
      'missed expected',
    );
    expect(p.generate).not.toHaveBeenCalled();
    expect(p.release).toHaveBeenCalledTimes(1);
  });
  it('returns transcription and generation and releases resources', async () => {
    const p = port();
    await expect(runFreedomPipeline(p)).resolves.toMatchObject({
      answer: 'Try pasta.',
    });
    expect(p.speak).toHaveBeenCalledWith('Try pasta.');
    expect(p.release).toHaveBeenCalledTimes(1);
  });
  it.each(['prepare', 'transcribe', 'generate', 'speak'] as const)(
    'releases resources after %s fails',
    async phase => {
      const p = port();
      p[phase].mockRejectedValueOnce(new Error(phase));
      await expect(runFreedomPipeline(p)).rejects.toThrow(phase);
      expect(p.release).toHaveBeenCalledTimes(1);
    },
  );
  it('rejects hallucinated/empty transcription before generation', async () => {
    const p = port();
    p.transcribe.mockResolvedValue('Thank you for watching.');
    await expect(runFreedomPipeline(p)).rejects.toThrow('missed expected');
    expect(p.generate).not.toHaveBeenCalled();
    expect(p.release).toHaveBeenCalledTimes(1);
  });
  it('rejects empty generation before playback', async () => {
    const p = port();
    p.generate.mockResolvedValue(' ');
    await expect(runFreedomPipeline(p)).rejects.toThrow('Empty local');
    expect(p.speak).not.toHaveBeenCalled();
  });
  it('cancellation after transcription skips generation and tears down', async () => {
    const p = port();
    let cancelled = false;
    p.transcribe.mockImplementation(async () => {
      cancelled = true;
      return 'cook dinner';
    });
    await expect(runFreedomPipeline(p, () => cancelled)).rejects.toThrow(
      'cancelled',
    );
    expect(p.generate).not.toHaveBeenCalled();
    expect(p.release).toHaveBeenCalledTimes(1);
  });
  it('does not report success when teardown fails', async () => {
    const p = port();
    p.release.mockRejectedValue(new Error('teardown'));
    await expect(runFreedomPipeline(p)).rejects.toThrow('teardown');
  });
});
