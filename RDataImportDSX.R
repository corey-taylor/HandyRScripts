#####	Preparation
#	Load libraries

library(plyr)

#####	Process data
#	Import tables
  
DSXScores <- read.table("DSXScores.txt", sep="")	#Import DSXScores
DSXScores <- rename(DSXScores, c("V1"="PoseID", "V2"="Score"))	#Rename columns
DSXScores$TRANS <- (DSXScores$Score)^2	#Transform

#	Stats

DSX_sd <- sd(DSXScores$TRANS)
DSX_mean <- mean(DSXScores$TRANS)
DSX_sd2 <- DSX_sd*2
DSX_2sig <- DSX_mean+DSX_sd2
DSXScores_2sig <- subset(DSXScores, TRANS > DSX_2sig, select=c(PoseID, TRANS))
write.table(DSXScores_2sig$PoseID, "DSXScores_2sig", sep="\t", col.names=FALSE, quote=FALSE, row.names=FALSE)    #output to file