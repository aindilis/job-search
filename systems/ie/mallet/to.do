(check out standoff.jar and anctool for doing conversion between
 inline and standoff annotations)

(here is the idea
 (

  instead of using the system as it is here, fix it to use FRDCSA
  NLU type spans.  Then convert the POS Tagger to generate NLU
  spans, and make an adaptor to preprocess the text into the span
  format first.  Then run NLU on the training and processing
  data, to add features.  Also email the list with everything to
  see how it's going.  Splice it into words <have the tokenizer
  work with NLU as well> and simply determine which tags subsume
  each token, add those as the features.

  ) 
 )
