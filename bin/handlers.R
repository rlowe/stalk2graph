require(ggplot2)

handlers_data<-read.csv("handlers.csv")

hw<-diff(handlers_data$write)
hu<-diff(handlers_data$update)
hd<-diff(handlers_data$delete)
hrf<-diff(handlers_data$read_first)
hrk<-diff(handlers_data$read_key)
hrl<-diff(handlers_data$read_last)
hrn<-diff(handlers_data$read_next)
hrp<-diff(handlers_data$read_prev)
hrr<-diff(handlers_data$read_rnd)
hrrn<-diff(handlers_data$read_rnd_next)

handlers_data<-data.frame(Time="", Handler="", Value=as.numeric(""))
handlers_data<-handlers_data[-1,]

for (i in 1:length(hw)) {
    handlers_data<-rbind( handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Write",
                                             Value=as.numeric(hw[i])))
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

jpeg('handlers.jpg')
ggplot(handlers_data, aes(x=Time, y=Value, fill=Handler, color=Handler, group=Handler, xaxt='n')) + geom_area(position = "stack", stat="identity") + ggtitle("MySQL Handlers")
dev.off()

