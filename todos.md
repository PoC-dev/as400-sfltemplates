## Check/Revise
- Probably use RNQxxxx for IBM provided translations of file status error codes: See QRNXMSG, e. g. RNQ1218.
  - Is this comprehensive to users?

## Probable bug
- Load-Paged, more records than one page
- Use pos-to for placing list start on a record which exactly is on the first
  line of the last page of data)
  - No scrolling back!

## More...
- Rework error handling - this will be really hard!
  - Current handler doesn't compile on V3
  - Current handler is very cumbersome to use (base indicator - 10)
- Can changes be put into a diff, and applied to existing applications?
  - https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html
- Lodpag: Save and restore selections when scolling.
