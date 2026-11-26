import React from 'react';
import {render} from '@testing-library/react-native';

import {AutomationBridge} from '../AutomationBridge';

// This suite checks the bridge's build-time gate and child wiring, not native
// adapter behavior. Do not start real store hydration/network work on import.
jest.mock('../adapters/FreedomAdapter', () => ({
  FreedomAdapter: () => 'FreedomAdapter',
}));
jest.mock('../adapters/MemoryAdapter', () => ({
  MemoryAdapter: () => 'MemoryAdapter',
}));
jest.mock('../adapters/TTSAdapter', () => ({
  TTSAdapter: () => 'TTSAdapter',
}));
jest.mock('../adapters/IapAdapter', () => ({
  IapAdapter: () => 'IapAdapter',
}));
jest.mock('../adapters/VoiceAdapter', () => ({
  VoiceAdapter: () => 'VoiceAdapter',
}));
jest.mock('../adapters/OnboardingBypass', () => ({
  OnboardingBypass: () => 'OnboardingBypass',
}));

describe('AutomationBridge', () => {
  const origE2E = (global as any).__E2E__;

  afterEach(() => {
    (global as any).__E2E__ = origE2E;
  });

  it('renders null when __E2E__ is false', () => {
    (global as any).__E2E__ = false;
    const {toJSON} = render(<AutomationBridge />);
    expect(toJSON()).toBeNull();
  });

  it('renders a non-null tree with adapter children when __E2E__ is true', () => {
    (global as any).__E2E__ = true;
    const {toJSON} = render(<AutomationBridge />);
    // Structural assertion only — adapter behavior is covered by
    // MemoryAdapter.test.tsx. Re-testing testID presence here would
    // duplicate that suite.
    expect(toJSON()).not.toBeNull();
    expect(toJSON()).toEqual([
      'FreedomAdapter',
      'MemoryAdapter',
      'TTSAdapter',
      'IapAdapter',
      'VoiceAdapter',
      'OnboardingBypass',
    ]);
  });
});
