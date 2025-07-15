A state management aims to provide a more unified structure and pattern thinking
as well as supports good maintenance for Flutter projects.

## Introduction

The pattern use a very different approach than existing common state managements
in market in order to try to overcome some their drawbacks and still sustain
fundamental abilities of debugging, expansion and maintenance:

The pattern is trying to

- Make the components (especially UI or widgets) easily reusable by removing the
  their dependency to observables.

- Introduce more unified architecture by treating components equally. There
  would no distinguish layers: presentation, repository and data.

- Add flexibility to the way of allocating the code by removing the abstract and
  ambiguous concept of separating between UI and logic. From that, it reduces
  the potential contain-too-much-code issue in one component.

Please refer to https://www.paperflutter.com for documentation and tutorial for
the pattern.
