/**
 * @jest-environment node
 * @jest-environment-options {"customExportConditions":["node","node-addons"]}
 */
const fs = require('fs');
const path = require('path');
const YAML = require('yaml');

const workflows = path.join(__dirname, '../../.github/workflows');
const readWorkflow = name =>
  YAML.parse(fs.readFileSync(path.join(workflows, name), 'utf8'));

describe('active Freedom workflow safety (not the upstream text fixtures)', () => {
  it('contains only the two approved lab workflows', () => {
    expect(fs.readdirSync(workflows).sort()).toEqual([
      'freedom-ios.yml',
      'freedom-testflight.yml',
    ]);
  });

  it('uses standard runners with read-only repository permissions', () => {
    const workflow = readWorkflow('freedom-ios.yml');
    expect(workflow.permissions).toEqual({contents: 'read'});
    expect(workflow.on.workflow_dispatch.inputs.run_native.default).toBe(true);
    expect(workflow.jobs.device.if).toBe(
      "github.event_name != 'workflow_dispatch' || (inputs.run_native && inputs.native_target != 'simulator')",
    );
    expect(workflow.jobs.simulator.if).toBe(
      "github.event_name != 'workflow_dispatch' || (inputs.run_native && inputs.native_target != 'device')",
    );
    expect(workflow.on.workflow_dispatch.inputs.native_target).toEqual({
      description: 'Native checks to run on a manual retry',
      type: 'choice',
      options: ['both', 'simulator', 'device'],
      default: 'both',
    });
    for (const job of Object.values(workflow.jobs)) {
      expect(['ubuntu-latest', 'macos-26']).toContain(job['runs-on']);
    }
  });

  it('does not create metered artifact uploads or dependency caches', () => {
    const workflow = readWorkflow('freedom-ios.yml');
    for (const job of Object.values(workflow.jobs)) {
      for (const step of job.steps) {
        expect(Boolean(step.run || step.uses)).toBe(true);
        expect(step.uses || '').not.toMatch(/upload-artifact/);
        expect(step.with?.cache).toBeUndefined();
      }
    }
  });

  it('keeps signing manual and requires explicit upload confirmation', () => {
    const workflow = readWorkflow('freedom-testflight.yml');
    expect(Object.keys(workflow.on)).toEqual(['workflow_dispatch']);
    expect(workflow.on.workflow_dispatch.inputs.confirm_upload.default).toBe(
      false,
    );
    expect(workflow.jobs.testflight.if).toBe('inputs.confirm_upload');
  });
});
