#' Apply the scaling factor R to get the most suitable locus-specific AF threshold.
#' @param tabindex The data.frame output from the \code{callsnvs} function. (if use.optimal.R = TRUE , tabindex must contain the column "case_mean_coverage"; use get_case_mean_coverage())
#' @param R The scaling factor R to adjust the AF threshold. default = 1 (neutral value, no changes)
#' @param use.optimal.R Automatically use the best scaling factor R given the mean coverage of the CASE sample and size of targeted regions. default: FALSE
#' @param target_size if use.optimal.R = TRUE, target size in Mb of the BED file as provided by the \code{get_target_size} fuction.
#' @return Given the combination of coverage, allelic fraction and pbem, return the most suitable scaling factor R to adjust the AF threshold.
#' @export
#' @examples
#' sample.info.file <- system.file("extdata", "test_sif_toy.tsv", package = "abemus")
#' outdir <- tempdir()
#' targetbed <- system.file("extdata", "regions_toy.bed", package = "abemus")
#' pacbamfolder_bychrom <- system.file("extdata", "pacbam_data_bychrom", package = "abemus")
#' pbem_dir <- system.file("extdata", "BaseErrorModel", package = "abemus")
#' controls_dir <- system.file("extdata", "Controls", package = "abemus")
#' m<-callsnvs(sample.info.file,outdir,targetbed,pbem_dir,controls_dir,pacbamfolder_bychrom,replicas=1)
#' tabindex <- m$tabsnvs_index
#' tabindex <- get_case_mean_coverage(tabindex = tabindex,pacbamfolder_bychrom = pacbamfolder_bychrom)
#' m$tabsnvs_index_scalfact <- apply_scaling_factor(tabindex = tabindex)
apply_scaling_factor <- function(tabindex,
                                 R = 1,
                                 use.optimal.R = FALSE,
                                 target_size = NA){

  if(use.optimal.R){

    #<check>
    if(!"case_mean_coverage"%in%colnames(tabindex)){
      message(paste("[",Sys.time(),"]\tError. column 'case_mean_coverage' must be present in tabindex when use.optimal.R = TRUE"))
      stop()
    }
    if(is.na(target_size)){
      message(paste("[",Sys.time(),"]\tError. 'target_size' needed when use.optimal.R = TRUE"))
      stop()
    }

    tabindex[,paste0("tabcalls_f3","_optimalR")] <- NA
    tabindex[,paste0("tabcalls_f3","_optimalR_used")] <- NA

    for(i in 1:nrow(tabindex)){
      a <- fread(input = tabindex$tabcalls_f3[i],stringsAsFactors = FALSE,data.table = FALSE)
      # select best R for this case sample

      sizes <- sort(unique(tab_optimal_R$target_Mbp))
      closest_target_size <- sizes[which(abs(sizes-target_size)==min(abs(sizes-target_size)))]

      bombanel <- tab_optimal_R[which(tab_optimal_R$target_Mbp == closest_target_size),]

      covs <- bombanel$mean_coverage
      closest_coverage <- covs[which(abs(covs-tabindex$case_mean_coverage[i])==min(abs(covs-tabindex$case_mean_coverage[i])))]

      optR <- bombanel$scalingfactor[which(bombanel$mean_coverage==closest_coverage)]

      a$filter.pbem_coverage <- a$filter.pbem_coverage * optR
      a$pass.filter.pbem_coverage <- 0
      a$pass.filter.pbem_coverage[which(a$af_case >= a$filter.pbem_coverage)] <- 1
      a <- a[which(a$pass.filter.pbem_coverage==1),]
      out.name <- gsub(basename(tabindex$tabcalls_f3[i]),pattern = "pmtab_F3_",replacement = paste0("pmtab_F3_optimalR_"))
      out.path <- gsub(tabindex$tabcalls_f3[i],pattern = basename(tabindex$tabcalls_f3[i]),replacement = out.name)
      #write.table(x = a,file = out.path,quote = FALSE,sep = "\t",row.names = FALSE,col.names = TRUE)
      tabindex[i,paste0("tabcalls_f3","_optimalR")] <- out.path
      tabindex[i,paste0("tabcalls_f3","_optimalR_used")] <- optR
    }
    message(paste("[",Sys.time(),"]\talright."))
    return(tabindex)

  } else {

    tabindex[,paste0("tabcalls_f3","_R",R)] <- NA
    for(i in 1:nrow(tabindex)){
      a <- fread(input = tabindex$tabcalls_f3[i],stringsAsFactors = FALSE,data.table = FALSE)
      a$filter.pbem_coverage <- a$filter.pbem_coverage * R
      a$pass.filter.pbem_coverage <- 0
      a$pass.filter.pbem_coverage[which(a$af_case >= a$filter.pbem_coverage)] <- 1
      a <- a[which(a$pass.filter.pbem_coverage==1),]
      out.name <- gsub(basename(tabindex$tabcalls_f3[i]),pattern = "pmtab_F3_",replacement = paste0("pmtab_F3_R",R,"_"))
      out.path <- gsub(tabindex$tabcalls_f3[i],pattern = basename(tabindex$tabcalls_f3[i]),replacement = out.name)
      #write.table(x = a,file = out.path,quote = FALSE,sep = "\t",row.names = FALSE,col.names = TRUE)
      tabindex[i,paste0("tabcalls_f3","_R",R)] <- out.path
    }
    message(paste("[",Sys.time(),"]\talright."))
    return(tabindex)

  }
}
