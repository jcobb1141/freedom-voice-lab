import React from 'react';
import * as RNFS from '@dr.pogodin/react-native-fs';

/**
 * Component-smoke startup only. Requires BOTH the E2E build and a local request
 * file installed by the CI launcher. Never requests microphone access.
 */
export const FreedomAdapter: React.FC = () => {
  React.useEffect(() => {
    if (!__E2E__) {
      return;
    }
    const request = `${RNFS.DocumentDirectoryPath}/freedom-request.json`;
    const status = `${RNFS.DocumentDirectoryPath}/freedom-result.json`;
    const start = async () => {
      if (!(await RNFS.exists(request))) {
        return;
      }
      const data = JSON.parse(await RNFS.readFile(request, 'utf8'));
      if (data.marker !== 'FREEDOM_NATIVE_REQUEST_V1') {
        throw new Error('Invalid Freedom startup request');
      }
      // Claim once, before loading optional native engines. A failed native
      // import must produce a result rather than an unexplained timeout.
      await RNFS.unlink(request);
      await RNFS.writeFile(
        status,
        JSON.stringify({state: 'starting', stage: 'import-native-adapter'}),
        'utf8',
      );
      const {runFreedomNative} = require('../freedomNative');
      await runFreedomNative();
    };
    start()
      .catch(async error => {
        await RNFS.writeFile(
          status,
          JSON.stringify({
            state: 'error',
            stage: 'startup-adapter',
            error: String(error),
            stack: error instanceof Error ? error.stack : undefined,
          }),
          'utf8',
        );
      })
      .catch(error => {
        console.warn('Freedom startup reporting failed:', String(error));
      });
  }, []);
  return null;
};
