# Global test
global_test = function(y, x, group, beta_hat, var_cov_hat, p_adj_method, alpha){
    x = x[, setdiff(colnames(x), "(Intercept)"), drop = FALSE]
    taxa_id = rownames(y)
    n_taxa = nrow(y)
    covariates = colnames(x)

    res_global = data.frame(matrix(NA, nrow = n_taxa, ncol = 4))
    rownames(res_global) = taxa_id
    colnames(res_global) = c("W", "p_val", "q_val", "diff_abn")

    group_ind = grepl(group, covariates)
    # Loop over the parameter of interest
    beta_hat_sub = beta_hat[, group_ind, drop = FALSE]
    var_cov_hat_sub = lapply(var_cov_hat, function(x) {
        x = x[-1, -1, drop = FALSE]
        x = x[group_ind, group_ind, drop = FALSE]
    })

    for (i in seq_len(n_taxa)) {
        # Loop over taxa
        beta_hat_sub_i = beta_hat_sub[i, ]
        var_cov_hat_sub_i = var_cov_hat_sub[[i]]
        A = diag(x = 1, nrow = length(beta_hat_sub_i))
        W = t(A %*% beta_hat_sub_i) %*%
            MASS::ginv(A %*% var_cov_hat_sub_i %*% t(A)) %*%
            (A %*% beta_hat_sub_i)
        p = 2 * min(pchisq(W, df = length(beta_hat_sub_i), lower.tail = TRUE),
                    pchisq(W, df = length(beta_hat_sub_i), lower.tail = FALSE))
        res_global[i, "W"] = W
        res_global[i, "p_val"] = p
    }
    # Model summary
    q_global = p.adjust(res_global[, "p_val"], method = p_adj_method)
    q_global[is.na(q_global)] = 1
    diff_global = q_global < alpha & !is.na(q_global)

    res_global$q_val = q_global
    res_global$diff_abn = diff_global
    return(res_global)
}
