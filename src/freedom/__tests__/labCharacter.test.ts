import {runInAction} from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';

import {palStore} from '../../store/PalStore';
import {palRepository} from '../../repositories/PalRepository';
import {
  FREEDOM_LAB_PAL_NAME,
  FREEDOM_LAB_SEEDED_KEY,
  FREEDOM_LAB_SYSTEM_PROMPT,
  freedomLabPalData,
} from '../labCharacter';

jest.mock('@react-native-async-storage/async-storage', () => {
  const values = new Map<string, string>();
  return {
    getItem: jest.fn(async (key: string) => values.get(key) ?? null),
    setItem: jest.fn(async (key: string, value: string) => {
      values.set(key, value);
    }),
    clear: jest.fn(async () => values.clear()),
    removeItem: jest.fn(async (key: string) => {
      values.delete(key);
    }),
  };
});

// Mock dependencies
jest.mock('../../utils/hfResolve', () => ({
  resolveHFModelForDownload: jest.fn(),
}));
jest.mock('../../repositories/PalRepository', () => ({
  palRepository: {
    getAllPals: jest.fn(),
    createPal: jest.fn(),
    updatePal: jest.fn(),
    deletePal: jest.fn(),
    getPalById: jest.fn(),
    getPalByPalshubId: jest.fn().mockResolvedValue(null),
    checkAndMigrateFromJSON: jest.fn(),
    getLocalPals: jest.fn(),
    getPalsHubPals: jest.fn(),
  },
}));

jest.mock('../../utils/imageUtils', () => ({
  downloadPalThumbnail: jest.fn(),
  deletePalThumbnail: jest.fn(),
}));

jest.mock('../../services', () => ({
  palsHubService: {
    getPals: jest.fn(),
    getPal: jest.fn(),
    getLibrary: jest.fn(),
    getMyPals: jest.fn(),
    getCategories: jest.fn(),
    getTags: jest.fn(),
    checkPalOwnership: jest.fn(),
  },
}));

// Mock MobX persist
jest.mock('mobx-persist-store', () => ({
  makePersistable: jest.fn(),
}));

const seed = async () => (palStore as any).initializeFreedomLabPal();
const countFreedom = () =>
  palStore.pals.filter(
    p => p.name === FREEDOM_LAB_PAL_NAME && p.source === 'local',
  ).length;

describe('Project FREEDOM voice lab character', () => {
  beforeEach(async () => {
    await AsyncStorage.removeItem(FREEDOM_LAB_SEEDED_KEY);
    runInAction(() => {
      palStore.pals = [];
    });
    (palRepository.createPal as jest.Mock).mockImplementation(
      async (palData: any) => ({
        ...palData,
        id: `freedom-${Math.random().toString(36).slice(2, 8)}`,
        created_at: '2026-11-24T00:00:00Z',
        updated_at: '2026-11-24T00:00:00Z',
      }),
    );
  });

  it('writes a prompt meant to be spoken, not read', () => {
    expect(FREEDOM_LAB_SYSTEM_PROMPT).toMatch(/spoken aloud/);
    expect(FREEDOM_LAB_SYSTEM_PROMPT).toMatch(/Never use markdown/);
    const data = freedomLabPalData();
    expect(data.type).toBe('local');
    expect(data.source).toBe('local');
    expect(data.systemPrompt).toBe(FREEDOM_LAB_SYSTEM_PROMPT);
  });

  it('seeds the character once', async () => {
    await seed();
    expect(countFreedom()).toBe(1);
    expect(await AsyncStorage.getItem(FREEDOM_LAB_SEEDED_KEY)).toBe('true');
    (palRepository.createPal as jest.Mock).mockClear();
    await seed();
    expect(countFreedom()).toBe(1);
    expect(palRepository.createPal).not.toHaveBeenCalled();
  });

  it('does not re-create the character after the user deletes it', async () => {
    await seed();
    runInAction(() => {
      palStore.pals = [];
    });
    (palRepository.createPal as jest.Mock).mockClear();
    await seed();
    expect(countFreedom()).toBe(0);
    expect(palRepository.createPal).not.toHaveBeenCalled();
  });
});
