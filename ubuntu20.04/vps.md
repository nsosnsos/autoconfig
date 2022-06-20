## vps instance config instruction

```bash
read -p "Input user name for github: " PARA_USER
read -p "Input user email for github: " PARA_EMAIL
ssh-keygen -t rsa -b 4096 -C "${PARA_EMAIL}"
git config --global user.name "${PARA_USER}"
git config --global user.email "${PARA_EMAIL}"
git clone git@github.com:${PARA_USER}/autoconfig.git
```

| ID | URL                                |
|:--:|:----------------------------------:|
| 1  | [VM1](https://127.0.0.1/)|
| 2  | [VM2](https://127.0.0.1/)|

---


f902a108-81db-4c8c-bdd7-9c6963b5ec8z
