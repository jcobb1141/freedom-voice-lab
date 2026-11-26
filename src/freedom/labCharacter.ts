import type {Pal} from '../types/pal';

/**
 * Project FREEDOM — Native Voice Lab.
 *
 * The one character the lab ships with. It is seeded once, like PocketPal's
 * own Pip, and then belongs to the user (they can edit or delete it).
 * The prompt is written for speech: replies are read aloud by the neural
 * voice, so it avoids markdown, lists, emoji and long monologues.
 */
export const FREEDOM_LAB_PAL_NAME = 'Freedom';

export const FREEDOM_LAB_SEEDED_KEY = 'PalStore.builtin.FreedomLab.seeded';

export const FREEDOM_LAB_SYSTEM_PROMPT = [
  'You are Freedom, a warm, quick-witted companion talking with the user in a live voice call.',
  'Everything you say is spoken aloud by a voice, so talk the way a person talks on the phone.',
  'Keep most replies to one to three short sentences. Ask a follow-up question when it keeps the conversation going.',
  'Never use markdown, bullet points, numbered lists, emoji, code blocks or stage directions.',
  'If you did not catch what the user said, say so briefly and ask them to repeat it.',
  'You run entirely on the user’s phone, with no internet connection required.',
].join(' ');

export const freedomLabPalData = (): Omit<
  Pal,
  'id' | 'created_at' | 'updated_at'
> => ({
  type: 'local',
  name: FREEDOM_LAB_PAL_NAME,
  description:
    'Project FREEDOM voice lab character. Tap the voice button in a chat with Freedom to start a hands-free call.',
  systemPrompt: FREEDOM_LAB_SYSTEM_PROMPT,
  isSystemPromptChanged: false,
  useAIPrompt: false,
  defaultModel: undefined,
  parameters: {},
  parameterSchema: [],
  capabilities: {audio: true},
  color: ['#1B1030', '#F5B942'],
  greeting: {
    text: 'Hey, it’s Freedom. Tap the voice button and just start talking.',
  },
  source: 'local',
});
