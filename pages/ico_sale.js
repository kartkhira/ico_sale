import Head from 'next/head'
import 'bulma/css/bulma.css'
import Web3 from 'web3'
import {useState} from 'react'

const ico_sale = () => {
    
    let web3 
    const [error, setError] = useState('')

    const connectWallethandler = async () =>{
        if(typeof window !== 'undefined' && typeof window.ethereum  !== "undefined")
            try {
                await window.ethereum.request({method : "eth_requestAccounts"})
                web3 = new Web3(window.ethereum)
            }catch(err){
                setError(err.message)
            }
        else
        {
            console.log("please install metamask")
        }
    }
    return (
        <div>
            <Head>
                <title>Whitelisted ICO Sale app  </title>
                <meta name="description" content="A minimal ICO sale app " />
            </Head>
            <nav class = "navbar mt-4 mb-4">
                <div class = "container">
                    <div class = "navbar-brand">
                        <h1>Whitelisted ICO offering </h1>
                    </div>
                    <div class = "navbar-end">
                        <button onClick = {connectWallethandler} class ="button is-primary">
                             Connect Wallet
                        </button>
                    </div>
                </div>
            </nav>
            <section>
                <div class = "container">
                    <p>Placeholder Text</p>    
                </div>
            </section>
            <section>
                <div class = "container has-text-danger">
                    <p>{error}</p>    
                </div>
            </section>
        </div>
    )
}

export default ico_sale