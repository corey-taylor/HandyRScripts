#!/bin/bash

#	Generate score tables to import into R

for SEEDINPUT in ../../SEED/SEED.ETP_CorrectedLibrary/outputs/FRAG0*clus_pproc.mol2
do
  NUMPOSES=$(awk 'NR==5 {print $3}' $SEEDINPUT)
  FRAGNUM=$(awk 'NR==11 {print $8}' $SEEDINPUT)
  awk 'f;/@<TRIPOS>SUBSTRUCTURE/{f=1}' $SEEDINPUT > out.txt
  if [ `ls -l out.txt | awk '{print $5}'` -eq 0 ]
    then
    echo "$SEEDINPUT has no data, ignoring."
    rm out.txt
  else
    echo "$SEEDINPUT has data, processing."
    sed -e "s/[[:space:]]\+/\t/g" out.txt > "F0"$FRAGNUM
    rm out.txt
  fi
done

#	Call R script to generate 2sig scores, fix output lists

rm .RData
rm .Rhistory
R CMD BATCH RDataImport.R
awk '{print "P0"$0".mol2"}' processedScores > out1 && mv out1 processedScores
awk '{print "P0"$0".mol2"}' processedScoresTRANS > out2 && mv out2 processedScoresTRANS
rm F0*

# Process SEED outputs, rename and clean up artifacts from PINGUI

for SEEDINPUT in ../../SEED/SEED.ETP_CorrectedLibrary/outputs/FRAG0*clus_pproc.mol2
do
  NUMPOSES=$(awk 'NR==5 {print $3}' $SEEDINPUT)
  python /home/taylorc/git_repos/PINGUI/pingui.py -s $NUMPOSES -i $SEEDINPUT
  for POUTPUT in 0*_[1-9]*.mol2
  do
    FRAGNUMP=$(awk 'f{print $2;f=0} /@<TRIPOS>SUBSTRUCTURE/{f=1}' $POUTPUT)
    perl -i -pe 's/.*/'$FRAGNUMP'/ if $.==4' $POUTPUT && mv $POUTPUT "P0"$FRAGNUMP".mol2"
  done
  for POUTPUT2 in P0*.mol2
  do
   grep -q -F "$POUTPUT2" processedScoresTRANS || rm "$POUTPUT2"
  done
done

# Rescoring with DSX

for POSES in P0*.mol2
do
  dsx_pdb -P ../../SEED/SEED.ETP_CorrectedLibrary/Inputs/ep_minh.mol2 -L $POSES
done

#	Extract scores, dump to file, delete unneeded DSX files

for DSXSCORES in DSX*.txt
do
  PoseID=$(awk -F '[:.]' 'NR==4 {print $2}' $DSXSCORES)
  Score=$(awk 'NR==35 {print $7; exit}' $DSXSCORES)
  echo $PoseID $Score >> DSXScores.txt
done

for DSX in DSX_ep_minh_*.txt
 do
  rm $DSX
done

#	Call R script to generate 2sig DSX scores, fix output list

rm .RData
rm .Rhistory
R CMD BATCH RDataImportDSX.R
awk '{print $0".mol2"}' DSXScores_2sig > out1 && mv out1 DSXScores_2sig

#	Use output from R to keep only good poses

for POUTPUT2 in P0*.mol2
 do
  grep -q -F "$POUTPUT2" DSXScores_2sig || rm "$POUTPUT2"
done