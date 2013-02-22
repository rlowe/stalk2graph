args<-commandArgs(trailingOnly = FALSE)

require(ggplot2)

transaction_handlers_data<-read.csv(args[length(args)])

thc<-diff(transaction_handlers_data$commit)
thr<-diff(transaction_handlers_data$rollback)
ths<-diff(transaction_handlers_data$savepoint)
thsr<-diff(transaction_handlers_data$savepoint_rollback)

transaction_handlers_data<-data.frame(Time="", Handler="", Value=as.numeric(""))
transaction_handlers_data<-transaction_handlers_data[-1,]

for (i in 1:length(hw)) {
    transaction_handlers_data<-rbind( transaction_handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Commit",
                                             Value=as.numeric(thc[i])))
    transaction_handlers_data<-rbind( transaction_handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Rollback",
                                             Value=as.numeric(thr[i])))
    transaction_handlers_data<-rbind( transaction_handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Savepoint",
                                             Value=as.numeric(ths[i])))
    transaction_handlers_data<-rbind( transaction_handlers_data,
                                  data.frame(Time=as.character(i),
                                             Handler="Savepoint Rollback",
                                             Value=as.numeric(thsr[i])))
}

jpeg('transaction_handlers.jpg')
ggplot(transaction_handlers_data, aes(x=Time, y=Value, fill=Handler, color=Handler, group=Handler, xaxt='n')) + geom_area(position = "stack", stat="identity") + ggtitle("MySQL Transaction Handlers")
dev.off()

