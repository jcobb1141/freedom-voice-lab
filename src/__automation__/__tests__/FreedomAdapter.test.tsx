import React from 'react';
import {render, waitFor} from '@testing-library/react-native';
import * as RNFS from '@dr.pogodin/react-native-fs';

import {FreedomAdapter} from '../adapters/FreedomAdapter';
import {runFreedomNative} from '../freedomNative';

jest.mock('@dr.pogodin/react-native-fs', () => ({
  DocumentDirectoryPath: '/test-documents',
  exists: jest.fn(),
  readFile: jest.fn(),
  writeFile: jest.fn(),
  unlink: jest.fn(),
}));
jest.mock('../freedomNative', () => ({runFreedomNative: jest.fn()}));

describe('Freedom component-smoke startup (mocked, not native execution)', () => {
  const original = (global as any).__E2E__;
  beforeEach(() => {
    jest.clearAllMocks();
    (global as any).__E2E__ = true;
    (RNFS.exists as jest.Mock).mockResolvedValue(true);
    (RNFS.readFile as jest.Mock).mockResolvedValue(
      JSON.stringify({marker: 'FREEDOM_NATIVE_REQUEST_V1'}),
    );
    (RNFS.writeFile as jest.Mock).mockResolvedValue(undefined);
    (RNFS.unlink as jest.Mock).mockResolvedValue(undefined);
    (runFreedomNative as jest.Mock).mockResolvedValue(undefined);
  });
  afterEach(() => {
    (global as any).__E2E__ = original;
    jest.restoreAllMocks();
  });

  it('does nothing outside an E2E build', () => {
    (global as any).__E2E__ = false;
    render(<FreedomAdapter />);
    expect(RNFS.exists).not.toHaveBeenCalled();
    expect(runFreedomNative).not.toHaveBeenCalled();
  });

  it('does not start without an explicit local request', async () => {
    (RNFS.exists as jest.Mock).mockResolvedValue(false);
    render(<FreedomAdapter />);
    await waitFor(() => expect(RNFS.exists).toHaveBeenCalled());
    expect(runFreedomNative).not.toHaveBeenCalled();
    expect(RNFS.writeFile).not.toHaveBeenCalled();
  });

  it('claims the request and writes a receipt before starting engines', async () => {
    render(<FreedomAdapter />);
    await waitFor(() => expect(runFreedomNative).toHaveBeenCalledTimes(1));
    expect(RNFS.unlink).toHaveBeenCalledWith(
      '/test-documents/freedom-request.json',
    );
    expect(JSON.parse((RNFS.writeFile as jest.Mock).mock.calls[0][1])).toEqual({
      state: 'starting',
      stage: 'import-native-adapter',
    });
    expect(
      (RNFS.writeFile as jest.Mock).mock.invocationCallOrder[0],
    ).toBeLessThan((runFreedomNative as jest.Mock).mock.invocationCallOrder[0]);
  });

  it('rejects an invalid request without starting engines', async () => {
    (RNFS.readFile as jest.Mock).mockResolvedValue('{"marker":"wrong"}');
    render(<FreedomAdapter />);
    await waitFor(() => expect(RNFS.writeFile).toHaveBeenCalled());
    expect(runFreedomNative).not.toHaveBeenCalled();
    const result = JSON.parse((RNFS.writeFile as jest.Mock).mock.calls[0][1]);
    expect(result.state).toBe('error');
    expect(result.error).toContain('Invalid Freedom startup request');
  });

  it('reports native startup failures instead of silently timing out', async () => {
    (runFreedomNative as jest.Mock).mockRejectedValueOnce(
      new Error('Missing native engine'),
    );
    render(<FreedomAdapter />);
    await waitFor(() => expect(RNFS.writeFile).toHaveBeenCalledTimes(2));
    const result = JSON.parse((RNFS.writeFile as jest.Mock).mock.calls[1][1]);
    expect(result.state).toBe('error');
    expect(result.error).toContain('Missing native engine');
  });

  it('contains a failure to write its own error report', async () => {
    (RNFS.writeFile as jest.Mock).mockRejectedValue(new Error('Disk full'));
    const warning = jest.spyOn(console, 'warn').mockImplementation(() => {});
    render(<FreedomAdapter />);
    await waitFor(() => expect(warning).toHaveBeenCalled());
    expect(runFreedomNative).not.toHaveBeenCalled();
  });
});
