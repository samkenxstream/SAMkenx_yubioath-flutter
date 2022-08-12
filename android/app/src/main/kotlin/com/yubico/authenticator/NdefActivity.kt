package com.yubico.authenticator

import android.app.Activity
import android.content.*
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import com.yubico.authenticator.Constants.Companion.EXTRA_OPENED_THROUGH_NFC
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.yubiclip.scancode.KeyboardLayout
import com.yubico.yubikit.core.util.NdefUtils
import java.nio.charset.StandardCharsets

typealias ResourceId = Int

class NdefActivity : Activity() {
    private lateinit var appPreferences: AppPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appPreferences = AppPreferences(this)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onPause() {
        super.onPause()
        overridePendingTransition(0, 0)
    }

    private fun handleIntent(intent: Intent) {
        intent.data?.let {
            if (appPreferences.copyOtpOnNfcTap) {
                try {
                    val otpSlotContent = parseOtpFromIntent()
                    setPrimaryClip(otpSlotContent.content)

                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.S_V2) {
                        showToast(
                            when (otpSlotContent.type) {
                                OtpType.Otp -> R.string.otp_success_set_otp_to_clipboard
                                OtpType.Password -> R.string.otp_success_set_password_to_clipboard
                            }, Toast.LENGTH_SHORT
                        )
                    }

                } catch (illegalArgumentException: IllegalArgumentException) {
                    Log.e(
                        TAG,
                        illegalArgumentException.message ?: "Failure when handling YubiKey OTP",
                        illegalArgumentException.stackTraceToString()
                    )
                    showToast(R.string.otp_parse_failure, Toast.LENGTH_LONG)
                } catch (_: UnsupportedOperationException) {
                    showToast(R.string.otp_set_clip_failure, Toast.LENGTH_LONG)
                }
            }

            if (appPreferences.openAppOnNfcTap) {
                val mainAppIntent = Intent(this, MainActivity::class.java).apply {
                    putExtra(EXTRA_OPENED_THROUGH_NFC, true)
                }
                startActivity(mainAppIntent)
            }

            finishAndRemoveTask()
        }
    }

    private fun showToast(value: ResourceId, length: Int) {
        Toast.makeText(this, value, length).show()
    }

    private fun parseOtpFromIntent(): OtpSlotValue {
        val parcelable = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
        if (parcelable != null && parcelable.isNotEmpty()) {
            val ndefPayloadBytes =
                NdefUtils.getNdefPayloadBytes((parcelable[0] as NdefMessage).toByteArray())

            return if (ndefPayloadBytes.all { it in 32..126 }) {
                OtpSlotValue(OtpType.Otp, String(ndefPayloadBytes, StandardCharsets.US_ASCII))
            } else {
                val kbd: KeyboardLayout = KeyboardLayout.forName(appPreferences.clipKbdLayout)
                OtpSlotValue(OtpType.Password, kbd.fromScanCodes(ndefPayloadBytes))
            }
        }
        throw IllegalArgumentException("Failed to parse OTP from the intent")
    }

    private fun setPrimaryClip(otp: String) {
        try {
            val clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboardManager.setPrimaryClip(ClipData.newPlainText(otp, otp))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to copy otp string to clipboard", e.stackTraceToString())
            throw UnsupportedOperationException()
        }
    }

    companion object {
        const val TAG = "YubicoAuthenticatorOTPActivity"
    }

    enum class OtpType {
        Otp, Password
    }

    data class OtpSlotValue(val type: OtpType, val content: String)
}