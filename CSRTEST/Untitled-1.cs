private void buttonGetPrivateKey_Click(object sender, EventArgs e)
{
    cspp.KeyContainerName = keyName;

    rsa = new RSACryptoServiceProvider(cspp);
    rsa.PersistKeyInCsp = true;

    if (rsa.PublicOnly == true)
        label1.Text = "Key: " + cspp.KeyContainerName + " - Public Only";
    else
        label1.Text = "Key: " + cspp.KeyContainerName + " - Full Key Pair";

}