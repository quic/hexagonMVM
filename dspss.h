/*
 * Copyright (c) 2025 Qualcomm Innovation Center, Inc. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef _DSPSS_H
#define _DSPSS_H

#define L2VIC_OFF_BYTES 0x10000
#define TIMER_OFF_BYTES 0x20000

// Hexagon Q6 core interrupt number for timer tick:
#define TIMER_INT_NUM (4)

// Offsets in bytes to the timer registers:
#define TIMER_REG_CNTSR  (0x0004)
#define TIMER_REG_CNTACR (0x0040)
#define TIMER_REG_CNTFRQ (0)
#define TIMER_REG_ENABLE (0x102c)

#define DEFAULT_CLK_FREQ_HZ (19200000)

#endif /* _DSPSS_H */
