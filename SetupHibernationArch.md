## Hibernation & Resume Guide for Arch Linux

This guide collects all necessary steps to enable reliable hibernation (suspend-to-disk) and resume on your machine running Arch Linux, with Btrfs root and a separate swap partition.

---

### Prerequisites

- **Linux swap partition** (≥ RAM size)
- Root filesystem on **Btrfs** (using a partition avoids swap-file complications)
- Proprietary **NVIDIA** GPU driver (If present)
- GRUB bootloader (EFI)

---

### 1. Verify Swap Partition

1. Identify your swap device and UUID:

   ```bash
   sudo blkid /dev/<swap-partition>
   ```

2. Confirm swap is active:

   ```bash
   swapon --show
   ```

Your swap UUID will be needed for kernel parameters and resume configuration.

---

### 2. Add `resume` Hook to Initramfs

1. **Edit** `/etc/mkinitcpio.conf` as root:

   ```ini
   # Find the HOOKS line and insert `resume` before `filesystems`
   HOOKS=(base udev autodetect modconf block resume filesystems keyboard fsck)
   # If using LUKS encryption:
   # HOOKS=(base udev autodetect modconf block encrypt resume filesystems keyboard fsck)
   ```

2. **Rebuild** all initramfs images:

   ```bash
   sudo mkinitcpio -P
   ```

This ensures the early userspace knows to include resume support before mounting filesystems.

---

### 3. Configure GRUB with `resume=UUID=`

1. **Edit** `/etc/default/grub`:

   ```ini
   # Add your swap UUID inside the quotes
   GRUB_CMDLINE_LINUX="quiet splash resume=UUID=<your-swap-UUID>"
   ```

2. **Regenerate** the GRUB configuration:

   ```bash
   sudo grub-mkconfig -o /boot/grub/grub.cfg
   sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --modules="tpm" --disable-shim-lock
   ```

3. **Reboot** into the updated environment.

---

### 4. Enable NVIDIA Sleep Hooks & Module Parameters

On Nvidia systems, the proprietary NVIDIA driver must be prepared for suspend/hibernate:

1. **Enable NVIDIA systemd services**:

   ```bash
   sudo systemctl enable \
     nvidia-suspend.service \
     nvidia-hibernate.service \
     nvidia-resume.service
   ```

2. **Create** `/etc/modprobe.d/nvidia-suspend.conf` with:

   ```conf
   options nvidia NVreg_PreserveVideoMemoryAllocations=1 \
                    NVreg_TemporaryFilePath=/var/tmp
   ```

3. **Update** initramfs again (if you created a new modprobe file):

   ```bash
   sudo mkinitcpio -P
   ```

This ensures the GPU is quiesced and VRAM preserved across hibernate.

---

### 5. Check BIOS ACPI Sleep State

1. Reboot and enter **BIOS** (usually by pressing **F2** or **Del**).
2. Navigate to **Config → Power → Sleep State**.
3. Set to **Linux** (ACPI **S3 suspend-to-RAM**), not Windows (Modern Standby/S0ix).
4. Save and exit.

Traditional S3 typically works best with Linux hibernate.

---

### 6. (Optional) Kernel Version Considerations

- Kernel **6.15.x** has had some hibernate/restore regressions; if issues persist:

  - Try the **LTS** kernel (e.g. 6.14.x) or a later update if available:

    ```bash
    sudo pacman -S linux-lts
    sudo mkinitcpio -P
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    ```

  - Monitor Arch/Laptop forums for patches or workarounds specific to the Legion 7i.

---

## Testing Hibernate

After completing the above steps, test hibernation:

```bash
systemctl hibernate
```

Your machine should:

1. Write RAM contents to swap → screen goes black.
2. Power off fully.
3. On power-on, restore your exact session state.

If it instead cold-boots, revisit steps above (check logs with `journalctl -b -1`).
