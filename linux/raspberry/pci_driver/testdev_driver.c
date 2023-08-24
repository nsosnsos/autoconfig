#include <linux/module.h>
#include <linux/init.h>
#include <linux/pci.h>


#define TESTDEV_VENDOR_ID 0x8888
#define TESTDEV_DEVICE_ID 0x6666


/* Meta information */
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Stan lee");
MODULE_DESCRIPTION("PCIe Driver for testdev");

static struct pci_device_id test_pci_ids[] = {
	{ PCI_DEVICE(TESTDEV_VENDOR_ID, TESTDEV_DEVICE_ID) },
	{ }
};
MODULE_DEVICE_TABLE(pci, test_pci_ids);


/**
 * @brief	probe a device
 *
 * @param dev	point to the PCI device
 * @param id	point to the corresponding id table's entry
 *
 * @return	0 on success
 *		negative error code on failure
 */
static int device_probe(struct pci_dev *dev, const struct pci_device_id *id){
	printk("testdev - probe a device.\n");
	return 0;
}

/**
 * @brief	remove a device
 *
 * @param dev	point to the PCI device
 **/
static void device_remove(struct pci_dev *dev) {
	printk("testdev - remove a device.\n");
}

/* PCI driver struct */
static struct pci_driver testdev_driver = {
	.name = "testdev driver",
	.id_table = test_pci_ids,
	.probe = device_probe,
	.remove = device_remove,
};

/**
 * @brief	init and register a device
 */
static int __init device_init(void) {
	printk("testdev - init module for testdev device.\n");
	return pci_register_driver(&testdev_driver);
}

/**
 * @brief	unregister a device
 */
static void __exit device_exit(void) {
	printk("testdev - exit module for testdev device.\n");
	pci_unregister_driver(&testdev_driver);
}

module_init(device_init);
module_exit(device_exit);
