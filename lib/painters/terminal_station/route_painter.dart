import 'package:flutter/material.dart';
import '../../screens/terminal_station_models.dart';
import '../../controllers/terminal_station_controller.dart';
import 'block_painter.dart';

/// Painter responsible for drawing route reservations
class RoutePainter {
  final BlockPainter _blockPainter = BlockPainter();

  void drawRouteReservations(
      Canvas canvas, TerminalStationController controller) {
    for (var reservation in controller.routeReservations.values) {
      final signal = controller.signals[reservation.signalId];
      if (signal == null) continue;

      bool shouldShowReservation = signal.routeState == RouteState.set ||
          controller.isRoutePendingCancellation(signal.id);

      if ((signal.id == 'C28' || signal.id == 'C30' || signal.id == 'C33') &&
          signal.aspect != SignalAspect.green &&
          !controller.isRoutePendingCancellation(signal.id)) {
        shouldShowReservation = false;
      }

      if (shouldShowReservation) {
        final isPendingCancellation =
            controller.isRoutePendingCancellation(signal.id);
        final reservationColor =
            isPendingCancellation ? Colors.orange : Colors.yellow;

        for (var blockId in reservation.reservedBlocks) {
          final block = controller.blocks[blockId];
          if (block == null) continue;

          if (reservation.signalId == 'C31' &&
              reservation.trainId.contains('C31_R1')) {
            if (blockId == '112') continue;
            if (blockId == '104' ||
                blockId == '106' ||
                blockId == '108' ||
                blockId == '110') {
              _blockPainter.drawBlockReservation(canvas, block, reservationColor);
            }
            continue;
          }

          if (reservation.signalId == 'C31' &&
              reservation.trainId.contains('C31_R2')) {
            if (blockId == '112') continue;
            if (blockId == '106') continue;
            if (blockId == '104' || blockId == '109' || blockId == '111') {
              _blockPainter.drawBlockReservation(canvas, block, reservationColor);
            }
            if (blockId == 'crossover106' || blockId == 'crossover109') {
              _blockPainter.drawCrossoverReservation(canvas, block, reservationColor);
            }
            continue;
          }

          if (reservation.signalId == 'C30' &&
              reservation.trainId.contains('C30_R1')) {
            if (blockId == '103' || blockId == '101') continue;
            if (blockId == 'crossover106' ||
                blockId == 'crossover109' ||
                blockId == '106' ||
                blockId == '108' ||
                blockId == '110') {
              continue;
            }
            if (blockId == '105' || blockId == '107' || blockId == '109') {
              _blockPainter.drawBlockReservation(canvas, block, reservationColor);
            }
            continue;
          }

          if (reservation.signalId == 'C30' &&
              reservation.trainId.contains('C30_R2')) {
            if (blockId == '106' || blockId == '108' || blockId == '110')
              continue;
            if (blockId == '107' ||
                blockId == '105' ||
                blockId == '103' ||
                blockId == '101') {
              continue;
            }
            if (blockId == '104' || blockId == '109') {
              _blockPainter.drawBlockReservation(canvas, block, reservationColor);
            }
            if (blockId == 'crossover106' || blockId == 'crossover109') {
              _blockPainter.drawCrossoverReservation(canvas, block, reservationColor);
            }
            continue;
          }

          if (blockId.startsWith('crossover')) {
            _blockPainter.drawCrossoverReservation(canvas, block, reservationColor);
          } else {
            _blockPainter.drawBlockReservation(canvas, block, reservationColor);
          }
        }

        final statusText = isPendingCancellation ? ' (Releasing...)' : '';
        final textPainter = TextPainter(
          text: TextSpan(
            text:
                '${reservation.signalId} → ${reservation.trainId.replaceAll('T', '').replaceAll('route_active', 'Active')}$statusText',
            style: TextStyle(
              color: reservationColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final firstBlock = controller.blocks[reservation.reservedBlocks.first];
        if (firstBlock != null) {
          textPainter.paint(
              canvas, Offset(firstBlock.startX + 5, firstBlock.y - 20));
        }
      }
    }
  }
}
