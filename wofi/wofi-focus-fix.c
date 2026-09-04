#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdbool.h>
#include <stddef.h>

typedef void GtkWidget;
typedef int gboolean;

extern void gtk_widget_grab_focus(GtkWidget*);
extern size_t gtk_entry_get_type(void);
extern int g_type_check_instance_is_a(void*, size_t);

/*
 * When wofi toggles search visibility in do_hide_search(), it sets entry visible and sensitive,
 * but omits grabbing focus on entry. This causes the first typed character to be processed as
 * a global keybinding (e.g. triggering key_submit if 'o' is typed, or key_down if 'j' is typed).
 * By intercepting gtk_widget_set_sensitive and grabbing focus whenever entry becomes sensitive,
 * entry immediately gains focus so that printable characters (including 'o', 'j', 'k') are
 * typed directly into the search field.
 */
void gtk_widget_set_sensitive(GtkWidget *widget, gboolean sensitive) {
    static void (*real_set_sensitive)(GtkWidget*, gboolean) = NULL;
    if (!real_set_sensitive) {
        real_set_sensitive = dlsym(RTLD_NEXT, "gtk_widget_set_sensitive");
    }
    real_set_sensitive(widget, sensitive);
    if (sensitive && widget && g_type_check_instance_is_a(widget, gtk_entry_get_type())) {
        gtk_widget_grab_focus(widget);
    }
}
