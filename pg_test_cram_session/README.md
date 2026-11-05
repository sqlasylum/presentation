# PostgreSQL DBA Practice Quizzes

This repository contains a browser-based PostgreSQL DBA quiz with two question
banks. Open [index.html](index.html) directly in a browser; no server or package
installation is required.

## Quiz Versions

Choose a bank using **Quiz Version**.

| Version | Questions | Domains |
| --- | --- | --- |
| AI Generated test questions | 80 | T1-T8 |
| Youtube content from Pavlo Golub | 64 | T1-T8 |

Answers, current question, submitted attempts and history clearing are scoped to
the selected version. The last selected version is restored when the page opens.
History review does not replace answers in an unfinished attempt. On Results,
click a review question to expand its full wording and four read-only choices.
The saved selection is checked and labeled; incorrect selections are highlighted
in red, and the correct choice is marked in green. Question summaries also open
with Enter or Space when focused.

The original bank stays embedded in the page. Its existing `quizHistory` and
`quizInProgress` browser-storage keys are unchanged. Additional banks use keys
such as `quizHistory:pavlo` and `quizInProgress:pavlo`. Storage is local to the
browser/profile and page location; moving the file or clearing browser data can
make saved attempts unavailable.

## Study Materials

- [PostgreSQL DBA practice exam](PostgreSQL_DBA1_Practice_Exam_04.md) and its
  [answer key](PostgreSQL_DBA1_Practice_Exam_04_Answer_Key.md)
- [Pavlo Golub source material](PG_Dba_Test_Cram.txt), used for the 64-question
  Pavlo quiz bank

## Adding Another Bank

1. Add a local JavaScript file following [pavlo-quiz.js](pavlo-quiz.js). Define a
   uniquely named data constant with `topics` and `questions`.
2. Load it with a regular script tag before the main inline script in
   [index.html](index.html). Regular local scripts keep direct file opening
   working without a JSON fetch or module server.
3. Add one entry to the page's `quizVersions` registry, using a permanent unique
   ID, a display `name`, and the bank's `data` constant. The selector and storage
   separation work from this registry without additional UI changes.

Each question has this shape:

```js
{
    id: 1,
    topic: 'T1',
    question: 'Question text?',
    options: ['Option A', 'Option B', 'Option C', 'Option D'],
    answer: 'C'
}
```

Use four distinct options, exactly one correct answer, a unique numeric question
ID and a topic present in `topics`. Treat question/option text as plain text, not
HTML. Keep an existing bank's question order and answer letters stable: saved
attempts refer to question positions and letters. Use a new version ID for a
revised or reordered bank that would invalidate old attempts.

## Pavlo Content Notes

The authoritative source is [PG_Dba_Test_Cram.txt](PG_Dba_Test_Cram.txt).
All 64 question strings and correct-answer options reproduce that source,
excluding the Q/A labels and surrounding whitespace. When proofreading is
requested, correct spelling, capitalization, punctuation, and grammar in the
source, then synchronize the quiz bank. Preserve technical meaning and do not add
hints or alter technical claims unless explicitly requested.

Only the three incorrect multiple-choice distractors per question are authored
separately. The existing 56 questions retain their IDs, order and correct-answer
letters so saved progress and attempts keep their original mappings. Domain 8 is
appended as questions 57-64. The original 80-question exam is unchanged.

The text file is not fetched at runtime; the page still opens directly from disk.
When updating Pavlo, synchronize the question and correct-answer strings in
[pavlo-quiz.js](pavlo-quiz.js) with the source and compare all 64 pairs before
finishing. Non-Q&A study notes are not converted into additional questions.
