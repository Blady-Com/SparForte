type nularr1 is array(1..0) of integer;
nularr : nularr1;
i : integer;

i := stats.min( nularr ); -- can't do on a null array

