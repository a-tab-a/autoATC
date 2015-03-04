###############################
#Defining the Kronecker delta summation operator
function kronSum(A,B)
    b = size(B,1)
    a = size(A,2)
    Ib = spdiagm(ones(b))
    Ia = spdiagm(ones(a))

    return kron(A,Ib) + kron(Ia,B)
end
#Handling lists
function kronSum(Alist)
  A = Alist[1]
  for j = 2:length(Alist)
    A = kronSum(A, Alist[j])
  end
  return A
end

###############################
#Kronecker vectors and matrices
function ev(i, m)
    e = spzeros(m,1)
    e[i] = 1.;
    return e;
end

function E(i,j,m,n)
    #Same as Em = ev(i,m) * ev(j,n)'
    Emn = spzeros(m,n)
    Emn[i,j] = 1.
    return Emn
end

###############################
function Ppq_v!(p,q, v)
    assert(issparse(v) && size(v,2)==1)
    #equivalent to v = Pcrazy(p,q) * v
    for i in v.colptr[1]:(v.colptr[2]-1)
        l = v.rowval[i]
        k = sub2ind((p,q), reverse(ind2sub((q,p),l))...)
        v.rowval[i] = k
    end
    return v
end

function Pmn(m,n)
    Pmn_ret = spzeros(m*n,m*n)
    for i in 1:m
        for j in 1:n
            k = sub2ind((n,m),j,i)
            l = sub2ind((m,n),i,j)
            Pmn_ret[k,l] = 1.
        end
    end
    return Pmn_ret
    #Slow version
    #Pmn = spzeros(m*n,m*n)
    #for i in 1:m
    #    for j in 1:n
    #        Eij = E(i,j,m,n)
    #        Pmn = Pmn + kron(Eij, Eij')
    #    end
    #end
    #return Pmn
end

###############################
#kron(ea,v)
###############################
function eaKronv(a,n,v)
    m = length(v)
    res = spzeros(n*m,1)
    idx = m*(a-1) + (1:m)
    res[idx] = v
    return res
end
#In place version.
function eaKronv!(a,n,v)
    offset = v.m*(a-1)
    v.m = v.m * n;
    for i in v.colptr[1]:(v.colptr[2]-1)
        v.rowval[i] =  offset + v.rowval[i]
    end
end
###############################
#This is the heart of most of it
function Cb(B,K,b)
    n = size(B,1);
    n_K = n^K;
    n_Km1 = n^(K-1);

    #Compute Cb
    Cb_res = spzeros(n_K,1);

    for u in 0:(K-1)
        p = n^u;
        q = n^(K-u)
        bp = sub2ind((p,q), reverse(ind2sub((q,p),b))...)
        (d,c) = ind2sub((n,n_Km1), bp)
        #res = kron(ec, B[d,:]')
        res_u = B[d,:]'
        eaKronv!(c, n_Km1, res_u)
        #Last step is to permute
        Ppq_v!(q,p,res_u)
        #Cumulative sum into accumulator
        Cb_res = Cb_res + res_u
    end

    return Cb_res
end
###############################
#This is the function that puts it all together!

function Qi(A,B,K,i)
    n = size(A,1)
    assert(n == size(A,2)) #enforce squareness
    assert(size(A) == size(B)) #only working with same size matrices

    n_K = n^K;
    (b, a) = ind2sub((n_K , n), i);

    res = Cb(B,K,b)
    eaKronv!(a,n,res)
    res = res + kron(A[a,:]', ev(b,n_K))

    return  res
end

#This is the lazy version
#pretty slow, and will run out
#out of memory for large n's
function Qi_lazy(A,B,K,i)
    Q = A;
    for k in 1:K
       Q = kronSum(Q,B)
    end

    return Q[i,:]'
end