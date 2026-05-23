# TensorBoard PR Reviewer Response Plan

This plan treats the current large PR as the approval/discussion base.
Goal for this round:

- clarify intent and necessity of each non-obvious change
- tighten comments/docs where low-risk
- identify follow-up PR candidates without weakening the current working branch

## Working approach

- Keep in this PR:
  - changes that are required for Bazel 7.7.0 + protobuf 6.31.1 to load, analyze, build, and test correctly
  - comments/docs that reduce reviewer confusion
- Candidate follow-up PRs:
  - CI/self-hosted runner cleanup
  - helper abstractions / repository helper cleanup
  - optional lazy-import cleanup if we can prove it is independent

## Comment-by-comment plan

### `.github/workflows/ci.yml`

#### Reviewer concern
- Is the Python header/setup-python workaround really needed?
- Is this due to Bazel 7, protobuf, or the self-hosted container?
- Prefer simpler setup or separate PR if possible.

#### Response plan
- Explain that this is primarily a CI environment issue:
  - Bazel's `system_python` repo resolves headers relative to the interpreter exposed by `setup-python`
  - in the self-hosted container, that include path does not already contain `Python.h`
  - the fix is needed for Bazel repo loading/builds in that environment
- Clarify that this is not caused by protobuf logic directly.
- Acknowledge that it is hacky and reasonable to split later.

#### Suggested PR action
- Keep current behavior for now if it is required for green CI.
- Add one short comment clarifying that the workaround is specific to the self-hosted `setup-python` + Bazel `system_python` interaction.

#### Follow-up candidate
- Yes. Revisit with:
  - newer `setup-python`
  - shell-installed Python in container
  - alternate Bazel python toolchain wiring

---

### Bazel 7 / bzlmod question

#### Reviewer concern
- Why upgrade to Bazel 7.7.0?
- Can we use Bazel modules instead?

#### Response plan
- Explain the immediate concrete benefit:
  - TensorFlow 2.21 uses Bazel 7.7.0
  - TensorBoard needs Bazel-side compatibility with that toolchain and dependency stack
  - the upgrade unblocks protobuf 6.31.1 and related dependency alignment
- Explain that bzlmod was not adopted in this PR because:
  - this branch already relies on several custom repository overrides, patches, and local repos
  - moving to bzlmod would be a larger dependency-management refactor than the minimum needed to align with TF 2.21

#### Suggested PR action
- No required code change.
- Add this explanation in PR replies / summary.

#### Follow-up candidate
- Yes. Separate investigation PR/issue for bzlmod adoption.

---

### Patch files and `patches/README.md`

#### Reviewer concern
- Add comments for why we are patching these files.
- Is `patch-package` still accurate?

#### Response plan
- Explain:
  - `patch-package` is still the authoring/generation mechanism for npm patches
  - this branch applies the generated patch artifacts through Bazel `yarn_install(post_install_patches=...)`
  - that avoids the less reliable install-time invocation inside the repository rule

#### Suggested PR action
- Keep the updated README wording, but improve it slightly if needed:
  - one sentence for generation path
  - one sentence for application path
- Add top-of-file rationale comments to:
  - `patches/protobuf_6_31_1_java_export.patch`
  - `patches/rules_cc_protobuf.patch`
  - `patches/rules_closure_soy_cli.patch`

#### Follow-up candidate
- No. This is good to clarify now.

---

### `tensorboard/compat/BUILD` and `tensorboard/compat/__init__.py`

#### Reviewer concern
- Is this Bazel-7-specific?
- Is it a fix or just cleanup?
- Could it be a separate PR?

#### Response plan
- Explain that this is a real fix, not cosmetic:
  - Bazel test runfiles were exposing a synthesized/incorrect package layout
  - that broke `from tensorboard.compat import tf` / `tf2`
  - the failure reproduced in both Bazel tests and wheel/runtime smoke tests
- Explain the package/layout fix and the added regression test.

#### Suggested PR action
- Keep the code change in this PR.
- Reword comments to avoid overfitting to a specific Bazel version:
  - use wording like "Bazel-generated package init/runfiles" rather than "Bazel 7" where possible

#### Follow-up candidate
- No. This is core correctness for the branch.

---

### `tensorboard/plugins/*/summary.py` lazy imports

#### Reviewer concern
- Why were lazy imports necessary?
- Could they be independent?

#### Response plan
- Explain that these were introduced to avoid import-time dependency cycles / eager import side effects through summary v2 modules while the compat/package wiring was being fixed.
- Be candid: these are more plausibly separable than the compat fix itself.

#### Suggested PR action
- Investigate whether all of these are still necessary after the compat/package fix.
- If they are no longer required, remove them from this PR.
- If still required, add one short comment in each file or one PR-level explanation.

#### Follow-up candidate
- Likely yes if they are merely defensive cleanup.

---

### `tensorboard/summary/writer/BUILD`

#### Reviewer concern
- Previous comment warned against pulling TensorFlow dependency here for internal builds.

#### Response plan
- Explain that the new dual dependency was added because:
  - `//tensorboard/compat` provides package-level `tf`/`tf2` exports
  - `//tensorboard/compat:tensorflow` provides the TF-or-stub wiring needed at runtime in Bazel runfiles
- Acknowledge the reviewer's concern about internal builds.

#### Suggested PR action
- Re-check whether `:tensorflow` is strictly necessary here.
- If it is necessary, restore some of the old context in the comment so reviewers understand we evaluated the internal-build concern.
- If a narrower dependency arrangement works, prefer that.

#### Follow-up candidate
- No if required for correctness; otherwise maybe split.

---

### `third_party/compatibility_proxy/proxy.bzl`

#### Reviewer concern
- Why add a proxy instead of just using newer `rules_java`?

#### Response plan
- Explain:
  - this shim exists to bridge symbol/layout expectations between TensorBoard's current repository usage and Bazel 7 / `rules_java`
  - it is intentionally tiny and only re-exports the Java symbols/infos TensorBoard needs
- Acknowledge that upgrading away from the shim would be preferable if it can be made to work cleanly.

#### Suggested PR action
- Add more explicit docstring/comments:
  - what loads this
  - which compatibility surface it preserves
  - why a shim was smaller/safer than a broader `rules_java` refactor in this PR

#### Follow-up candidate
- Yes. Investigate replacing with a cleaner upstream-supported `rules_java` usage.

---

### `third_party/protobuf_pip_deps/requirements.bzl`

#### Reviewer concern
- Why is this shim needed?
- What calls these methods?

#### Response plan
- Explain:
  - protobuf's Bazel build expects a `requirement()` / `install_deps()` style pip dependency API
  - TensorBoard does not use a full pip repo setup for protobuf's Bazel-side needs here
  - the shim satisfies the small subset protobuf actually asks for on this branch

#### Suggested PR action
- Expand docstring/comments to say:
  - this is loaded by protobuf's Bazel build macros
  - only `numpy` and `setuptools` are needed in this branch's execution path

#### Follow-up candidate
- No urgent split needed unless reviewer strongly prefers.

---

### `third_party/repo.bzl`

#### Reviewer concern
- What do helper functions return/do?
- Is `ctx` being modified?
- Could this be a separate PR?

#### Response plan
- Explain:
  - `tb_http_archive` centralizes mirror URL + patch + link-file behavior already repeated in this PR
  - `ctx.path(Label(...))` in the validation loop is only forcing label resolution early; it is not mutating `ctx`
- Acknowledge this helper is more "infrastructure cleanup" than direct feature work.

#### Suggested PR action
- Add clearer docstrings/comments to:
  - `_get_link_dict`
  - `_tb_http_archive_impl`
  - why patch labels are resolved before download/extract
- Consider whether this helper can be split later if reviewer strongly prefers.

#### Follow-up candidate
- Yes, plausible split candidate.

---

### `third_party/werkzeug.BUILD`

#### Reviewer concern
- Why was `imports = ["."]` necessary?

#### Response plan
- Explain that Bazel package import roots changed enough on this stack that Werkzeug needed an explicit import root to preserve the expected `werkzeug.*` imports from the vendored package layout.

#### Suggested PR action
- Add a short comment above `imports = ["."]`.

#### Follow-up candidate
- No, tiny and harmless to explain in place.

---

### `.bazelrc`

#### Reviewer concern
- Should flags have comments?
- Is TensorFlow mention necessary in C++17 comment?

#### Response plan
- Explain:
  - `--enable_platform_specific_config` is there so the OS-specific C++17 flags below are actually picked up
  - the C++17 requirement is primarily driven by protobuf 6.31.1; TF alignment is supporting context, not the core reason

#### Suggested PR action
- Add/adjust comments:
  - explain `--enable_platform_specific_config`
  - rephrase C++17 comment to center protobuf 6.31.1 requirement, with TF alignment as secondary

#### Follow-up candidate
- No.

---

### `WORKSPACE` vendoring / `safe_html_types`

#### Reviewer concern
- Can we avoid vendoring and use `http_archive` instead?
- Can comments move above the `local_repository`?
- Why are some deps using `tb_http_archive` and others plain `http_archive`?
- What needs Soy and why these extra Java deps?
- Do `rules_closure_dependencies(...) omit_*` entries correspond to the custom deps above?

#### Response plan
- Explain:
  - `safe_html_types` is the main true vendored code in this PR
  - it is a build-time Java dependency for the existing Closure/Soy toolchain, not TensorBoard runtime code
  - the local copy is used because this branch needs a protobuf-6-compatible adjusted version of those classes, not just any upstream release
  - the `omit_*` entries are exactly what stop `rules_closure_dependencies` from re-introducing older/conflicting transitive versions of the same Java deps
  - `tb_http_archive` is used where we needed common mirror/patch/link behavior; plain `http_archive` remains where that helper was not yet applied or where we stayed closer to upstream declarations

#### Suggested PR action
- Keep vendoring for now unless we can prove an exact upstream archive works unchanged with protobuf 6.31.1.
- Improve comments in `WORKSPACE`:
  - move the vendor rationale above `local_repository`
  - add one comment before `com_google_template_soy`
  - add one comment before `rules_closure_dependencies(...)` explaining the `omit_*` linkage
- Expand `third_party/safe_html_types/README.md`:
  - what is vendored
  - why it is needed
  - why it is safe
  - why it is local_repository instead of a plain archive in this branch

#### Follow-up candidate
- Yes. Investigate replacing the vendor with an archive-based source if an exact compatible upstream source can be identified.

---

### `urllib3` / `six` note from reviewer

#### Reviewer concern
- There were related PRs; maybe `six` is no longer needed.

#### Response plan
- Explain that this was mainly part of local/container reproduction friction rather than the core Bazel/protobuf change.

#### Suggested PR action
- Avoid over-emphasizing it in the main PR description.
- If there are remaining direct changes related to this in the branch, consider removing or minimizing them unless still required.

#### Follow-up candidate
- Yes, if anything remains here.

## Recommended immediate edits before replying

- tighten `WORKSPACE` comments around `safe_html_types`, Soy deps, and `omit_*`
- add more explanatory docstrings/comments in:
  - `third_party/repo.bzl`
  - `third_party/compatibility_proxy/proxy.bzl`
  - `third_party/protobuf_pip_deps/requirements.bzl`
  - `third_party/werkzeug.BUILD`
  - `.bazelrc`
- generalize the `tensorboard/compat/BUILD` comment so it is not overly Bazel-7-specific
- improve `third_party/safe_html_types/README.md` with the explicit vendored-code explanation
- add reason comments to the patch files

## Recommended "reply without code change" items

- Bazel 7 benefit / bzlmod question
- CI self-hosted `setup-python` hack origin and rationale
- why this PR is currently kept broad as an approval base before splitting

## Recommended likely split candidates later

- CI/self-hosted runner setup cleanup
- `third_party/repo.bzl` helper extraction/cleanup
- possibly the summary lazy-import changes, if we confirm they are independent of the compat fix
