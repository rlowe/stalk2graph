args<-commandArgs(trailingOnly = FALSE)

require(ggplot2)

handlers_data<-read.csv(args[length(args)-1])

hq<-(handlers_data$write)
hu<-(handlers_data$update)
hd<-(handlers_data$delete)
hrf<-(handlers_data$read_first)
hrk<-(handlers_data$read_key)
hrl<-(handlers_data$read_last)
hrn<-(handlers_data$read_next)
hrp<-(handlers_data$read_prev)
hrr<-(handlers_data$read_rnd)
hrrn<-(handlers_data$read_rnd_next)

handlers_data<-data.frame(Time="", Handler="", Value=as.numeric(""))
handlers_data<-handlers_data[-1,]

for (i in 1:length(hu)) {
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Write",
                                             Value=as.numeric(hq[i])))
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Update",
                                             Value=as.numeric(hu[i])))
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Delete",
                                             Value=as.numeric(hd[i])))
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Read First",
                                             Value=as.numeric(hrf[i])))
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Read Key",
                                             Value=as.numeric(hrk[i])))
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Read Last",
                                             Value=as.numeric(hrl[i])))
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Read Next",
                                             Value=as.numeric(hrn[i])))
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Read Prev",
                                             Value=as.numeric(hrp[i])))
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Read Rnd",
                                             Value=as.numeric(hrr[i])))
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Read Rnd Next",
                                             Value=as.numeric(hrrn[i])))
}

png(args[length(args)],width=800)
options(scipen=20)
ggplot(handlers_data, aes(x=Time, y=Value, fill=Handler, color=Handler, group=Handler, xaxt='n')) + geom_area(position = "stack", stat="identity") + ggtitle("MySQL Handlers") + theme(axis.title.y = element_blank(), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank())
dev.off()

