package com.yubico.authenticator.keystore

import android.security.keystore.KeyProperties
import android.security.keystore.KeyProtection
import com.yubico.yubikit.oath.AccessKey
import java.security.KeyStore
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

class KeyStoreProvider : KeyProvider {
    private val keystore = KeyStore.getInstance("AndroidKeyStore")

    init {
        keystore.load(null)
    }

    override fun hasKey(deviceId: String): Boolean = keystore.containsAlias(deviceId)

    override fun getKey(deviceId: String): AccessKey? =
        if (hasKey(deviceId)) {
            KeyStoreStoredSigner(deviceId)
        } else {
            null
        }

    override fun addKey(deviceId: String, secret: ByteArray) {
        keystore.setEntry(
            deviceId,
            KeyStore.SecretKeyEntry(
                SecretKeySpec(secret, KeyProperties.KEY_ALGORITHM_HMAC_SHA1)
            ),
            KeyProtection.Builder(KeyProperties.PURPOSE_SIGN).build()
        )
    }


    override fun removeKey(deviceId: String) {
        keystore.deleteEntry(deviceId)
    }

    override fun clearAll() {
        keystore.aliases().asSequence().forEach { keystore.deleteEntry(it) }
    }

    private inner class KeyStoreStoredSigner(val deviceId: String) :
        AccessKey {
        val mac: Mac = Mac.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA1).apply {
            init(keystore.getKey(deviceId, null))
        }

        override fun calculateResponse(challenge: ByteArray?): ByteArray? = mac.doFinal(challenge)
    }
}
