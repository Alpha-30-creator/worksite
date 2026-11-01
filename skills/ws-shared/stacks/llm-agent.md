# Stack: llm-agent

Selected by `stack: [llm-agent]`. Any repo that runs a model with tools in a loop — in the
examples, `kestrel-ai`, whose agent lives under `app/agent/` as a graph plus `prompts/`,
`tools/`, `routing.py` and `tiers.py`. Applies to any change that alters **what the agent decides**:
the prompt, the tool set, a tool's description or schema, the routing, the memory, the tiers.

**A fix that names the failing case is overfitting.** A keyword list, a branch keyed on the
example input, a sentence appended to the prompt naming the one scenario from the bug report —
each makes that transcript pass and teaches the agent nothing. Name the class the failure
belongs to, then fix at that level. If the class cannot be named, the cause is not understood
yet.

**Prove it on a case that is not the one that failed.** Re-running the transcript that surfaced
the bug only shows the bug was memorised. Evidence is: the failing case, two or three
neighbours that should now behave the same way, and one that should still behave *differently*
— because most agent fixes over-apply, and that regression is invisible if you only re-run the
one case.

**Prefer giving the agent capability over removing its choice.** In order:
the context it was missing → a tool that can do the thing → a clearer tool description or
schema (it knows *when* to use it) → a clearer instruction in the prompt (it knows what is
wanted) → and only then a constraint. A constraint is capability removed **everywhere**, not
only in the case that failed.

**A constraint is sometimes right — say so out loud, and say what the agent may no longer do.**
Legitimate reasons: safety, money, an irreversible write, a permission boundary, an external
contract. "The model got it wrong once" is not one of them. An undeclared constraint is a
finding.

**Scaffolding is the expensive answer; the prompt is usually the cheap one.** A new wrapper,
orchestrator, validation layer or retry ladder is more code, more state and more failure modes
than the sentence that would have done. Try context, tool description and prompt first, and say
why they were not enough before building the layer.

**The prompt is code.** Review a prompt diff line by line like any other diff — a removed
sentence is a removed behaviour, and a growing pile of appended special cases is the overfit
above in its most common form. If a prompt is only getting longer, the instruction underneath
is wrong.

**A tool's description is its interface.** The model sees only the name, the description and
the schema. An argument renamed without its description, an enum widened without saying what
the new value means, a tool added without saying when *not* to use it — each is a contract
change, judged like an API change.

**Non-determinism means evidence, not reasoning.** No agent behaviour change can be proved by
reading the diff. Run it, and save the transcripts. Where a repo has no test net at all, the
transcripts you actually produced are the entire record — and whether that is the case is a fact
about that project, so it belongs in its `risks/`, not here.

**LangChain/LangGraph specifically — a sync `before_model` hook runs on the event loop, not in
an executor.** LangChain passes
an async form to LangGraph only when `abefore_model` is overridden; otherwise
`RunnableCallable.ainvoke` calls the sync function directly. Any middleware that touches the
network, a database or a file store must implement `abefore_model` and push its I/O through
`asyncio.to_thread` — a blocking call there stalls every request on the worker, not just its
own turn.
