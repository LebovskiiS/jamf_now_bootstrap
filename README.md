# Jamf Now skript (manual onboard)

Eto repo delayet **ruchnoy start** dlya macOS mashin cherez **Jamf Now Open Enrollment**.
On stavit enroll profil (esli ty das ssylku) i prilipaet local security baseline cherez `.mobileconfig`. Tuda zhe vklyucheno: firewall, gatekeeper, policy na parol, FileVault defer i logi pishutsya.

> Hocesh avtomat DEP/ABM + Jamf Pro, smotri drugoy proekt:
> **[jamf\_pro\_bootstrap](https://github.com/LebovskiiS/jamf_pro_bootstrap)**

---

## Chto eto / ne eto

**Eto:**

* Ruchnoy start na Mac dlya enroll v Jamf Now Open Enrollment i baseline.
* Znaet macOS versiyu 13/14/15 i beret pravilnyy folder.
* Mojet rasshirit’sya hookami (pre/post/unenroll).
* Est logi i tracking state chtoby snimat chestno.

**Ne eto:**

* Ne zero-touch avtomat DEP.
* Ne zamena central policy v Jamf. Eto tolko pervyy shag.

---

## Layout repo

```
.
├─ bootstrap.sh      # glavnoy skript
├─ uninstall.sh      # snimaet profili, proba unenroll
├─ quickstart.sh     # wrapper, sam znaet OS, pishi .env
├─ .env_example      # primer env file
├─ hooks/
│  ├─ prebaseline.d/
│  ├─ postbaseline.d/
│  └─ unenroll.d/
└─ mobileconfigs/
   └─ macos/
      ├─ sequoia/   # macOS 15
      ├─ sonoma/    # macOS 14
      └─ ventura/   # macOS 13
```

> Starshe macOS 13 ne podderzhivaetsya — nado obnova.

---

## Trebovaniya

* Mac s macOS 13/14/15.
* (optional) Jamf Now Open Enrollment link (`https://go.jamfnow.com/XXXXX`).
* Admin prava (sudo).
* (optional) Slack webhook dlya notif.

---

## Quick start

```bash
git clone git@github.com:LebovskiiS/jamf_now_bootstrap.git
cd jamf_now_bootstrap
chmod +x quickstart.sh bootstrap.sh uninstall.sh
./quickstart.sh
```

Helper:

* sam naidet macOS versiyu
* sprosit enrollment URL
* sprosit Slack
* zapishet v `.env`
* zapustit bootstrap

Logi v **/var/log/mdm-onboard.log**

---

## Env vars

```bash
ENROLL_PROFILE_URL="https://go.jamfnow.com/XXXXX" \
BASELINE_DIR="mobileconfigs/macos/sonoma" \
sudo -E ./bootstrap.sh
```

* `ENROLL_PROFILE_URL` — enrollment link
* `BASELINE_DIR` — folder s mobileconfig
* `SLACK_WEBHOOK_URL` — optional Slack

---

## Chto delayet bootstrap

* Proverka macOS i vibor baseline.
* Stavit MDM enroll profil (esli URL est’).
* Stavit vse baseline `.mobileconfig`.
* Uzhestochka bezopasnosti po **NIST 800-53 rev5 High** (farmacia ready):

  * Firewall on
  * Gatekeeper on
  * Parol 12+ char, mixed, cifra, simvol
  * FileVault defer
* Pishut’sya logi, vivod profil id.
* Mozhet kinut Slack notif.

---

## Hooks

* `hooks/prebaseline.d/*.sh` — do install baseline.
* `hooks/postbaseline.d/*.sh` — posle install baseline.
* `hooks/unenroll.d/*.sh` — pri uninstall.

---

## Uninstall

```bash
sudo ./uninstall.sh
```

* snimaet profili kotorie stavil
* probuet snimat enroll profil
* gonyaet `unenroll.d/*.sh`

---

## Ogranicheniya

* Jamf Now enrollment vsyo ravno sprosit user code.
* Tolko macOS, nichego dlya Windows/Linux.
* Zero-touch tolko cherez Jamf Pro.

---

## FAQ

**Gde vzyat URL?** — v Jamf Now Open Enrollment page.

**Nado li menyat dlya raznyh macOS?** — net, skript sam vyberet.

**Mogu li dodelat EDR/VPN agent?** — da, kladi v postbaseline hook.

**Gde smotret chto bylo?** — v `/var/log/mdm-onboard.log`.

---

## License

MIT
