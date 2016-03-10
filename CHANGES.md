## Version 0.1.0

 - working crdsa with maximum number of iterations
 - more compact code in sic.m, but no significant changes
 - working version of crdsa without packet retransmission (lossy MAC)
 - crdsa ready for testing
 - fixed buggy SIC function: now non-collided twins are canceled, too; and the cycle is iterated throughout all acknowledged packets
 - fixed bug: the RAF matrix should be initialized at the beginning of every iteration; otherwise it crowds up and the interference cancellation becomes impossible
 - the random backoff interval is no longer assigned to  collided sources; they transmit again in the next Random Access Frame.
 - fixed bug in case of backlogged source (if it was, nothing was done)
 - added conditional in case of no akc'ed packets
 - preliminary version for testing
 - Backoff management completely reworked
 - started to evaluate number of successes and collisions
 - Merge branch 'feature/interference-cancellation' into develop
 - Successive Interference Cancellation deployed as a standalone function.
 - successive interference cancellation now working, with elimination of acked twin packets
 - Fixed bug that prevented the interference cancellation to work properly
 - first (buggy) version of successive interference cancellation
 - cleaned up the output
 - Bare first version (script and not a function): create Randrom Access Frames and detect successfull packets, returning slot id and source id
 - Create README.md
 - Initial commit

