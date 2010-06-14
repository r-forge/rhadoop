library("tm.plugin.dc")
library("multicore")

#tgz <-  "/home/stheussl/Data/nyt/nyt_dtm_sources.tar.gz"

#path <- "/tmp/theussl_NYT"
#dir.create(path)
#system(sprintf("tar xzf %s -C %s", tgz, path))
path <- "/scratch/9157.1.bignode.q/incoming"

.read_lines_from_reducer_output <- function( path, cores = 4L )
  mclapply( .get_chunks_from_revision(path),
          function(x) {
            #cat(sprintf("processing chunk '%s'", x), sep = "\n")
            lapply(lapply( readLines(x), function(line) strsplit(line, "\t") ),
                   function(keyvalue) list(keyvalue[[1]][1],
                                           tm.plugin.dc:::dc_unserialize_object(keyvalue[[1]][2])))
         }, mc.cores = cores )

.get_chunks_from_revision <- function(path)
  file.path( path, grep("part-", dir(path),
                              value =TRUE) )

construct_term_list <- function( DTM_results, cores = 2L ){
  structure( do.call(c,
               mclapply(DTM_results, function(x) lapply(x, function(e) e[[2]]),
                        mc.cores = cores) ), names = unlist(mclapply(DTM_results, function(x) unlist(lapply(x, function(e) e[[1]])), mc.cores = cores)) )
}

term_list <- construct_term_list( .read_lines_from_reducer_output(path) )

NYT_DTM <- tm:::.TermDocumentMatrix( i    = rep(seq_along(term_list),
                                   unlist(lapply(term_list, function(x) length(x[[ 2 ]])))),
                                     j    = unlist(lapply(term_list, function(x) x[[ 1 ]])),
                                     v    = as.numeric(unlist(lapply(term_list, function(x) x[[ 2 ]]))),
                                     nrow = length(term_list),
                                        #ncol = length(x),
                                     ncol = 1700000,
                                     dimnames = list(Terms = names(term_list), Docs = as.character(seq_len(1700000))) )

save(DTM_results, file = "DTM_results.rda")
